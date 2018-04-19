module Bench.Pos.Criterion.Block.Logic
    ( runBenchmark
    ) where

import           Universum

import           Control.Lens (lens, makeLensesWith)
import           Control.Monad.Random.Strict (evalRandT)
import           Criterion.Main (Benchmarkable, bench, defaultConfig, defaultMainWith, perRunEnv)
import           Criterion.Types (Config (..))
import           Data.Cache.LRU (newLRU)
import           Data.Default (def)
import qualified Data.HashMap.Strict as HM
import qualified Data.List.NonEmpty as NE
import qualified Data.Map.Strict as Map
import           Ether.Internal (HasLens (..))
import           Mockable.Production (Production (..))
import           Mockable.CurrentTime (realTime)
import           System.Random (newStdGen)
import           System.Wlog (LoggerName (..))

import           Network.Broadcast.OutboundQueue.Types (NodeType (..))

import           Pos.AllSecrets (mkAllSecretsSimple)
import           Pos.Block.BListener (MonadBListener (..), onApplyBlocksStub, onRollbackBlocksStub)
import           Pos.Block.Error (VerifyBlocksException)
import           Pos.Block.Logic.VAR (verifyBlocksPrefix)
import           Pos.Block.Slog (SlogGState (..), HasSlogGState (..))
import           Pos.Block.Types (Undo)
import           Pos.Binary.Class ()
import           Pos.Core.Block (Block)
import           Pos.Core.Common (BlockCount (..))
import           Pos.Core.Configuration (HasConfiguration, genesisHash)
import           Pos.Core.Genesis (GenesisWStakeholders (..))
import           Pos.Core.Slotting (EpochIndex (..), Timestamp (..))
import           Pos.Core.Ssc (mkCommitmentsMap)
import           Pos.DB (DBSum (PureDB))
import           Pos.DB.Block (dbGetSerBlockPureDefault, dbGetSerUndoPureDefault, dbPutSerBlundsPureDefault)
import           Pos.DB.Class (MonadDB (..), MonadDBRead (..), MonadGState (..))
import           Pos.DB.DB (initNodeDBs, gsAdoptedBVDataDefault)
import           Pos.DB.Pure (DBPureVar, dbGetPureDefault, dbIterSourcePureDefault, newDBPureVar, dbPutPureDefault, dbWriteBatchPureDefault, dbDeletePureDefault)
import           Pos.Delegation.Class (DelegationWrap (..), DelegationVar)
import           Pos.Delegation.Configuration (DlgConfiguration (..), withDlgConfiguration, dlgCacheParam)
import           Pos.Generator.Block (BlockGenMode, BlockGenParams (..), TxGenParams (..), genBlocks)
import           Pos.GState (GStateContext (..), HasGStateContext (..))
import           Pos.KnownPeers (MonadFormatPeers (..))
import           Pos.Launcher.Configuration (ConfigurationOptions (..), defaultConfigurationOptions, HasConfigurations, withConfigurationsM)
import           Pos.Lrc.Context (LrcContext (..), LrcSyncData (..))
import           Pos.Network.Types (HasNodeType (..))
import           Pos.Reporting (HasReportingContext (..), ReportingContext (..))
import           Pos.Slotting
import           Pos.Slotting.Types (EpochSlottingData (..), createInitSlottingData)
import           Pos.Slotting.Impl.Simple (mkSimpleSlottingStateVar)
import           Pos.Ssc (SscState (..), SscLocalData (..), SscGlobalState (..), SscState, SscMemTag)
import qualified Pos.Ssc.VssCertData as Vss
import           Pos.Txp (MempoolExt, MonadTxpLocal (..), txNormalize, txProcessTransactionNoLock)
import           Pos.Txp.Settings.Global (TxpGlobalSettings)
import           Pos.Txp.Logic.Global (txpGlobalSettings)
import           Pos.Update.Poll.Modifier (PollModifier)
import           Pos.Util.Chrono (OldestFirst (..), NE)
import           Pos.Util.Lens (postfixLFields)
import           Pos.Util.CompileInfo (HasCompileInfo, withCompileInfo, retrieveCompileTimeInfo)

config :: Config
config = defaultConfig
    { reportFile = Just "verification.html"
    }

data BenchContext = BenchContext {
    -- requirements of `verifyBlocksPrefix`
      bcSimpleSlottingStateVar :: SimpleSlottingStateVar
    , bcSlottingTimestamp :: Timestamp
    , bcDelegationVar :: DelegationVar
    , bcSscState :: SscState
    , bcTxpGlobalSettings :: TxpGlobalSettings
    , bcGStateContext :: GStateContext
    }

makeLensesWith postfixLFields ''BenchContext

newBenchContext :: (HasConfiguration) => IO BenchContext
newBenchContext =
    withDlgConfiguration
        (DlgConfiguration
            { ccDlgCacheParam = 100
            , ccMessageCacheTimeout = 100000
            })
        $ do
            bcSimpleSlottingStateVar <- mkSimpleSlottingStateVar
            let slottingData = createInitSlottingData (EpochSlottingData 3600000 0) (EpochSlottingData 3600000 0)
            let bcSlottingTimestamp = Timestamp 0
            bcDelegationVar <- newTVarIO $ DelegationWrap
                { _dwMessageCache = (newLRU $ Just dlgCacheParam)
                , _dwProxySKPool = mempty
                , _dwPoolSize = 1
                , _dwTip = genesisHash
                }
            let bcTxpGlobalSettings = txpGlobalSettings
            let sscGlobalState = SscGlobalState
                    { _sgsCommitments = mkCommitmentsMap []
                    , _sgsOpenings = HM.empty
                    , _sgsShares = HM.empty
                    , _sgsVssCertificates = Vss.empty
                    }
            let sscLocalData = SscLocalData
                    { _ldModifier = mempty
                    , _ldEpoch = EpochIndex 0
                    , _ldSize = 0
                    }
            bcSscState <- SscState <$> newTVarIO sscGlobalState <*> newTVarIO sscLocalData
            let lrcSyncData = LrcSyncData
                    { lrcNotRunning = True
                    , lastEpochWithLrc = EpochIndex 0
                    }
            -- GStateContext
            _gscDB <- PureDB <$> newDBPureVar
            _gscLrcContext <- LrcContext <$> newTVarIO lrcSyncData
            _gscSlogGState <- SlogGState <$> newIORef (OldestFirst [])
            _gscSlottingVar <- newTVarIO slottingData
            let bcGStateContext = GStateContext {..}
            return BenchContext {..}

type BenchMode = ReaderT BenchContext Production

runBenchModeIO
    :: ReaderT BenchContext Production t
    -> BenchContext
    -> IO t
runBenchModeIO benchMode benchCtx = runProduction $ runReaderT benchMode benchCtx

instance HasLens SimpleSlottingStateVar BenchContext SimpleSlottingStateVar where
    lensOf = bcSimpleSlottingStateVar_L

instance HasSlottingVar BenchContext where
    slottingTimestamp = bcSlottingTimestamp_L
    slottingVar       = bcGStateContext_L . gscSlottingVar

instance ( HasConfiguration
         , MonadSlotsData ctx BenchMode
         ) => MonadSlots ctx BenchMode where
  getCurrentSlot           = getCurrentSlotSimple
  getCurrentSlotBlocking   = getCurrentSlotBlockingSimple
  getCurrentSlotInaccurate = getCurrentSlotInaccurateSimple
  currentTimeSlotting      = currentTimeSlottingSimple

instance HasConfiguration => MonadDBRead BenchMode where
    dbGet = dbGetPureDefault
    dbIterSource = dbIterSourcePureDefault
    dbGetSerBlock = dbGetSerBlockPureDefault
    dbGetSerUndo = dbGetSerUndoPureDefault

instance HasLens DBPureVar BenchContext DBPureVar where
    -- Note: the getter is a partial function: `DBSum` has two constructors, but
    -- we assume `PureDB`.
    lensOf = bcGStateContext_L . gscDB . lens (\(PureDB pureDB) -> pureDB) (\_ pureDB -> PureDB pureDB)

instance HasConfiguration => MonadGState BenchMode where
    gsAdoptedBVData = gsAdoptedBVDataDefault

instance HasLens DelegationVar BenchContext DelegationVar where
    lensOf = bcDelegationVar_L

instance HasLens SscMemTag BenchContext SscState where
    lensOf = bcSscState_L

instance HasLens LrcContext BenchContext LrcContext where
    lensOf = bcGStateContext_L . gscLrcContext

instance HasLens TxpGlobalSettings BenchContext TxpGlobalSettings where
    lensOf = bcTxpGlobalSettings_L

instance MonadFormatPeers BenchMode where
    formatKnownPeers _ = pure Nothing

-- fake reporting context
instance HasReportingContext BenchContext where
  reportingContext  = lens getter setter
    where
    getter _ = ReportingContext [] mempty Nothing
    setter s _ = s

instance HasNodeType BenchContext where
    getNodeType _ = NodeEdge

instance HasSlogGState BenchContext where
    slogGState = bcGStateContext_L . gscSlogGState

instance MonadBListener BenchMode where
    onApplyBlocks = onApplyBlocksStub
    onRollbackBlocks = onRollbackBlocksStub

instance HasGStateContext BenchContext where
    gStateContext = bcGStateContext_L

type instance MempoolExt BenchMode = ()

instance HasConfigurations => MonadTxpLocal (BlockGenMode () BenchMode) where
    txpNormalize = withCompileInfo def $ txNormalize
    txpProcessTx = withCompileInfo def $ txProcessTransactionNoLock

instance HasConfiguration => MonadDB BenchMode where
    dbPut = dbPutPureDefault
    dbWriteBatch = dbWriteBatchPureDefault
    dbDelete = dbDeletePureDefault
    dbPutSerBlunds = dbPutSerBlundsPureDefault

verifyBlocksPrefixBench
    :: ( HasConfigurations
       , HasCompileInfo
       )
    => BenchContext
    -> BlockCount
    -> Benchmarkable
verifyBlocksPrefixBench ctx bCount = perRunEnv (runBenchModeIO genEnv ctx) benchBlockVerification
    where
    genEnv :: BenchMode (OldestFirst NE Block)
    genEnv = do
        g <- liftIO $ newStdGen
        bs <- flip evalRandT g $ genBlocks
                (BlockGenParams
                    { _bgpSecrets = mkAllSecretsSimple []
                    , _bgpBlockCount = bCount
                    , _bgpTxGenParams = TxGenParams
                        { _tgpTxCountRange = (0, 10)
                        , _tgpMaxOutputs = 10
                        }
                    , _bgpInplaceDB = False
                    , _bgpSkipNoKey = False
                    , _bgpGenStakeholders = GenesisWStakeholders Map.empty
                    , _bgpTxpGlobalSettings = txpGlobalSettings
                    })
                (map fst . maybeToList)
        return $ OldestFirst $ NE.fromList bs

    benchBlockVerification
        :: ( HasConfigurations
           , HasCompileInfo
           )
        => (OldestFirst NE Block)
        -> IO (Either VerifyBlocksException (OldestFirst NE Undo, PollModifier))
    benchBlockVerification blocks =
        runProduction $ runReaderT (verifyBlocksPrefix blocks) ctx

runBenchmark :: IO ()
runBenchmark = do
    startTime <- realTime
    withCompileInfo $(retrieveCompileTimeInfo) $
        let co = defaultConfigurationOptions
                    { cfoFilePath = "../lib/configuration.yaml"
                    , cfoKey = "test"
                    , cfoSystemStart = Just (Timestamp startTime)
                    }
        in withConfigurationsM (LoggerName "verifyBlocksPrefixBench") co $ \_ -> do
            ctx <- newBenchContext
            runBenchModeIO initNodeDBs ctx
            defaultMainWith config
                [ bench "verifyBlocksPrefixBench" $ verifyBlocksPrefixBench ctx (BlockCount 2000) ]
