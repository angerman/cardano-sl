{ args ? { config = import ./config.nix; }
, nixpkgs ? import <nixpkgs>
}:
let
  pkgs = nixpkgs args;
  overrideWith = override: default:
   let
     try = builtins.tryEval (builtins.findFile builtins.nixPath override);
   in if try.success then
     builtins.trace "using search host <${override}>" try.value
   else
     default;
in
let
  # all packages from hackage as nix expressions
  hackage = import (overrideWith "hackage"
                    (pkgs.fetchFromGitHub { owner  = "angerman";
                                            repo   = "hackage.nix";
                                            rev    = "d8e03ec0e3c99903d970406ae5bceac7d993035d";
                                            sha256 = "0c7camspw7v5bg23hcas0r10c40fnwwwmz0adsjpsxgdjxayws3v";
                                            name   = "hackage-exprs-source"; }))
                   ;
  # a different haskell infrastructure
  haskell = import (overrideWith "haskell"
                    (pkgs.fetchFromGitHub { owner  = "angerman";
                                            repo   = "haskell.nix";
                                            rev    = "a3122dd1e1bee134c8a5a30af2a0e5eaaaf8e94f";
                                            sha256 = "0ib1bxz341di2kxi526b3cmps8y3x5hadahgp8lh4l1405xr1icz";
                                            name   = "haskell-lib-source"; }))
                   hackage;

  # the set of all stackage snapshots
  stackage = import (overrideWith "stackage"
                     (pkgs.fetchFromGitHub { owner  = "angerman";
                                             repo   = "stackage.nix";
                                             rev    = "67675ea78ae5c321ed0b8327040addecc743a96c";
                                             sha256 = "1ds2xfsnkm2byg8js6c9032nvfwmbx7lgcsndjgkhgq56bmw5wap";
                                             name   = "stackage-snapshot-source"; }))
                   ;

  # our packages
  stack-pkgs = import ./.stack-pkgs.nix;

  # Build the packageset with module support.
  # We can essentially override anything in the modules
  # section.
  #
  #  packages.cbors.patches = [ ./one.patch ];
  #  packages.cbors.flags.optimize-gmp = false;
  #
  pkgSet = haskell.mkNewPkgSet {
    inherit pkgs;
    pkg-def = stackage.${stack-pkgs.resolver};
    modules = [
      stack-pkgs.module
      # We use some customized libiserv/remote-iserv/iserv-proxy
      # instead of the ones provided by ghc. This is mostly due
      # to being able to hack on them freely as needed.
      #
      # iserv is only relevant for template-haskell execution in
      # a cross compiling setup.
      {
        packages.ghci         = import /p/iohk/ghc/libraries/ghci;
        packages.ghc-boot     = import /p/iohk/ghc/libraries/ghc-boot;
        packages.libiserv     = import ../libiserv-8.5;
        packages.remote-iserv = import ../remote-iserv-8.5;
        packages.iserv-proxy  = import ../iserv-proxy-8.5;
      }
      ({ config, lib, ... }: {
        packages = {
          hsc2hs = config.hackage.configs.hsc2hs."0.68.4".revisions.default;
          # stackage 12.17 beautifully omitts the Win32 pkg
          Win32 = config.hackage.configs.Win32."2.6.2.0".revisions.default;
        };
      })
      {
               # This needs true, otherwise we miss most of the interesting
         # modules.
         packages.ghci.flags.ghci = true;
         # this needs to be true to expose module
         #  Message.Remote
         # as needed by libiserv.
         packages.libiserv.flags.network = true;
      }
      ({ config, ... }: {
          packages.hsc2hs.components.exes.hsc2hs.doExactConfig= true;
          packages.Win32.components.library.build-tools = [ config.hsPkgs.buildPackages.hsc2hs ];
#          packages.Win32.components.library.doExactConfig = true;
          packages.remote-iserv.postInstall = ''
            cp ${pkgs.windows.mingw_w64_pthreads}/bin/libwinpthread-1.dll $out/bin/
          '';
      })
      {
        packages.conduit.patches            = [ ./patches/conduit-1.3.0.2.patch ];
        packages.cryptonite-openssl.patches = [ ./patches/cryptonite-openssl-0.7.patch ];
        packages.streaming-commons.patches  = [ ./patches/streaming-commons-0.2.0.0.patch ];
        packages.x509-system.patches        = [ ./patches/x509-system-1.6.6.patch ];

        packages.file-embed-lzma.patches    = [ ./patches/file-embed-lzma-0.patch ];
      }
      ({ lib, ... }: {
        # packages.cardano-sl-infra.configureFlags = lib.mkForce [ "--ghc-option=-v3" ];
        # packages.cardano-sl-infra.components.library.configureFlags = lib.mkForce [ "--ghc-option=-v3" ];
#        packages.cardano-sl-infra.components.library.configureFlags = [ "-v" "--ghc-option=-v3" ];
#        packages.cardano-sl-infra.components.library.setupBuildFlags = [ "-v" ];
      })
      # cross compilation logic
      ({ pkgs, buildModules, config, lib, ... }:
      let
        buildFlags = map (opt: "--ghc-option=" + opt) [
          "-fexternal-interpreter"
          "-pgmi" "${config.hsPkgs.buildPackages.iserv-proxy.components.exes.iserv-proxy}/bin/iserv-proxy"
          "-opti" "127.0.0.1" "-opti" "$PORT"
          # TODO: this should be automatically injected based on the extraLibrary.
          "-L${pkgs.windows.mingw_w64_pthreads}/lib"
          "-L${pkgs.gmp}/lib"
        ];
        preBuild = ''
          # unset the configureFlags.
          # configure should have run already
          # without restting it, wine might fail
          # due to a too large environment.
          unset configureFlags
          PORT=$((5000 + $RANDOM % 5000))
          echo "---> Starting remote-iserv on port $PORT"
          WINEDLLOVERRIDES="winemac.drv=d" WINEDEBUG=-all+error WINEPREFIX=$TMP ${pkgs.buildPackages.winePackages.minimal}/bin/wine64 ${packages.remote-iserv.components.exes.remote-iserv}/bin/remote-iserv.exe tmp $PORT &
          echo "---| remote-iserv should have started on $PORT"
          RISERV_PID=$!
        '';
        postBuild = ''
          echo "---> killing remote-iserv..."
          kill $RISERV_PID
        '';
        withTH = { setupBuildFlags = buildFlags; inherit preBuild postBuild; };
        in {
         packages.generics-sop      = withTH;
         packages.ether             = withTH;
         packages.th-lift-instances = withTH;
         packages.aeson             = withTH;
         packages.hedgehog          = withTH;
         packages.th-orphans        = withTH;
         packages.uri-bytestring    = withTH;
         packages.these             = withTH;
         packages.katip             = withTH;
         packages.swagger2          = withTH;
         packages.wreq              = withTH;
         packages.wai-app-static    = withTH;
         packages.cardano-sl-util   = withTH;
         packages.cardano-sl-crypto = withTH;
         packages.cardano-sl-crypto-test = withTH;
         packages.log-warper        = withTH;
         packages.cardano-sl-core   = withTH;
         packages.cardano-sl        = withTH;
         packages.cardano-sl-chain  = withTH;
         packages.cardano-sl-db     = withTH;
         packages.cardano-sl-networking = withTH;
         packages.cardano-sl-infra  = withTH;
         packages.cardano-sl-client = withTH;
         packages.cardano-sl-core-test = withTH;
         packages.cardano-sl-chain-test = withTH;
         packages.cardano-sl-utxo   = withTH;
         packages.math-functions    = withTH;
         packages.servant-swagger-ui = withTH;
         packages.servant-swagger-ui-redoc = withTH;
         packages.cardano-sl-wallet-new = withTH;
         packages.cardano-sl-tools    = withTH;
         packages.trifecta            = withTH;
      })
      # packages we wish to ignore version bounds of.
      # this is similar to jailbreakCabal, however it
      # does not require any messing with cabal files.
      {
         packages.katip.components.library.doExactConfig         = true;
         packages.serokell-util.components.library.doExactConfig = true;
      }
    ];
  };

  packages = pkgSet.config.hsPkgs // { _config = pkgSet.config; };

in packages
