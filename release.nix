let
  fixedLib     = import ./lib.nix;
  fixedNixpkgs = fixedLib.fetchNixPkgs;
in
  { supportedSystems ? [ "x86_64-linux" "x86_64-darwin" ]
  , scrubJobs ? true
  , cardano ? { outPath = ./.; rev = "abcdef"; }
  , fasterBuild ? false
  , skipDocker ? false
  , skipPackages ? []
  , nixpkgsArgs ? {
      config = (import ./nix/config.nix // { allowUnfree = false; inHydra = true; });
      gitrev = cardano.rev;
      inherit fasterBuild;
    }
  }:

with (import (fixedNixpkgs + "/pkgs/top-level/release-lib.nix") {
  inherit supportedSystems scrubJobs nixpkgsArgs;
  packageSet = import ./.;
});

let
  iohkPkgs = import ./. { gitrev = cardano.rev; };
  pkgs = import fixedNixpkgs { config = {}; };
  shellEnv = import ./shell.nix { };
  wrapDockerImage = cluster: let
    images = {
      mainnet = iohkPkgs.dockerImages.mainnet;
      staging = iohkPkgs.dockerImages.staging;
    };
    wrapImage = image: pkgs.runCommand "${image.name}-hydra" {} ''
      mkdir -pv $out/nix-support/
      cat <<EOF > $out/nix-support/hydra-build-products
      file dockerimage ${image}
      EOF
    '';
  in {
    wallet = wrapImage images."${cluster}".wallet;
    explorer = wrapImage images."${cluster}".explorer;
  };
  platforms = removeAttrs {
    all-cardano-sl = supportedSystems;
    cardano-report-server = [ "x86_64-linux" ];
    cardano-report-server-static = [ "x86_64-linux" ];
    cardano-sl = supportedSystems;
    cardano-sl-auxx = supportedSystems;
    cardano-sl-chain = supportedSystems;
    cardano-sl-cluster = [ "x86_64-linux" ];
    cardano-sl-core = supportedSystems;
    cardano-sl-crypto = supportedSystems;
    cardano-sl-db = supportedSystems;
    cardano-sl-explorer = [ "x86_64-linux" ];
    cardano-sl-explorer-frontend = [ "x86_64-linux" ];
    cardano-sl-explorer-static = [ "x86_64-linux" ];
    cardano-sl-generator = supportedSystems;
    cardano-sl-infra = supportedSystems;
    cardano-sl-networking = supportedSystems;
    cardano-sl-node-static = supportedSystems;
    cardano-sl-tools = supportedSystems;
    cardano-sl-tools-post-mortem = supportedSystems;
    cardano-sl-util = supportedSystems;
    cardano-sl-wallet-new = supportedSystems;
    cardano-sl-x509 = supportedSystems;
    daedalus-bridge = supportedSystems;
    shells.cabal = supportedSystems;
    shells.stack = supportedSystems;
    stack2nix = supportedSystems;

    # nix-tools toolchain: Libraries
    nix-tools.cardano-sl            = supportedSystems;
    nix-tools.cardano-sl-auxx       = supportedSystems;
    nix-tools.cardano-sl-chain      = supportedSystems;
    nix-tools.cardano-sl-core       = supportedSystems;
    nix-tools.cardano-sl-crypto     = supportedSystems;
    nix-tools.cardano-sl-db         = supportedSystems;
    nix-tools.cardano-sl-generator  = supportedSystems;
    nix-tools.cardano-sl-infra      = supportedSystems;
    nix-tools.cardano-sl-networking = supportedSystems;
    nix-tools.cardano-sl-tools      = supportedSystems;
    nix-tools.cardano-sl-util       = supportedSystems;
    nix-tools.cardano-sl-wallet-new = supportedSystems;
    nix-tools.cardano-sl-x509       = supportedSystems;

    # nix-tools toolchain: Executables
    # these will usually implicitly build their
    # library as they depend on it.
    nix-tools.exes.cardano-sl-tools             = supportedSystems;
    nix-tools.exes.cardano-sl-generator         = supportedSystems;
    nix-tools.exes.cardano-sl-tools-post-mortem = supportedSystems;
    nix-tools.exes.cardano-sl-wallet-new        = supportedSystems;

    # nix-tools toolchain: Tests
    # TBD

  } skipPackages;
  platforms' = removeAttrs {
    connectScripts.mainnet.wallet   = [ "x86_64-linux" "x86_64-darwin" ];
    connectScripts.mainnet.explorer = [ "x86_64-linux" "x86_64-darwin" ];
    connectScripts.staging.wallet   = [ "x86_64-linux" "x86_64-darwin" ];
    connectScripts.staging.explorer = [ "x86_64-linux" "x86_64-darwin" ];
    connectScripts.testnet.wallet   = [ "x86_64-linux" "x86_64-darwin" ];
    connectScripts.testnet.explorer = [ "x86_64-linux" "x86_64-darwin" ];
  } skipPackages;
  mapped = mapTestOn platforms;

  # this is quite stupid, and I'd prefer to be able to
  # set the $X->$Y as part of the supportedSystems, however
  # this is completely contrary to how nixpkgs wants this
  # to do;  and trying to bend nixpkgs to my needs has resulted
  # in loosing valuable amounts of hair.
  #
  # At the same time nixpkgs (master) started changing the
  # appraoch in yet another incompatible way. As such we are
  # likely stuck with this for a bit longer.
  #
  # Note that, intead of the custom system/crossSystem hack we
  # did in cardano-sl#3291, we try to find a more unified appraoch
  # here.
  crossTests =
    let
      lin = f: testOnCross lib.systems.examples.mingwW64 [ "x86_64-linux" ] f;
      mac = f: testOnCross lib.systems.examples.mingwW64 [ "x86_64-darwin" ] f;
      libs = [ "cardano-sl" ];
      exes = [ "cardano-sl-wallet-new" "cardano-sl-tools" ];
    in
      { nix-tools =
       (builtins.foldl'
         (acc: x: acc // { ${x} = {
           "x86_64-linux->mingwW64"  = lin (pkgs: pkgs.nix-tools.${x});
           "x86_64-darwin->mingwW64" = mac (pkgs: pkgs.nix-tools.${x}); }; })
         {}
         libs)
        // { exes = (builtins.foldl'
         (acc: x: acc // { ${x} = {
           "x86_64-linux->mingwW64"  = lin (pkgs: pkgs.nix-tools.exes.${x});
           "x86_64-darwin->mingwW64" = mac (pkgs: pkgs.nix-tools.exes.${x}); }; })
         {}
         exes); }; };

  mapped' = mapTestOn platforms';
  makeConnectScripts = cluster: let
  in {
    inherit (mapped'.connectScripts."${cluster}") wallet explorer;
  };
  nixosTests = import ./nixos-tests;
  tests = iohkPkgs.tests;
  makeRelease = cluster: {
    name = cluster;
    value = {
      connectScripts = makeConnectScripts cluster;
    } // fixedLib.optionalAttrs (! skipDocker) {
      dockerImage = wrapDockerImage cluster;
    };
  };
  # return an attribute set containing the result of running every test-suite in cardano, on the given system
  makeCardanoTestRuns = system:
  let
    pred = name: value: fixedLib.isCardanoSL name && value ? testrun;
    cardanoPkgs = import ./. { inherit system; };
    f = name: value: value.testrun;
  in pkgs.lib.mapAttrs f (lib.filterAttrs pred cardanoPkgs);
in pkgs.lib.fix (jobsets: mapped // crossTests // {
  inherit tests;
  inherit (pkgs) cabal2nix;
  nixpkgs = let
    wrapped = pkgs.runCommand "nixpkgs" {} ''
      ln -sv ${fixedNixpkgs} $out
    '';
  in if 0 <= builtins.compareVersions builtins.nixVersion "1.12" then wrapped else fixedNixpkgs;
  # the result of running every cardano test-suite on 64bit linux
  all-cardano-tests.x86_64-linux = makeCardanoTestRuns "x86_64-linux";
  # hydra will create a special aggregate job, that relies on all of these sub-jobs passing
  required = pkgs.lib.hydraJob (pkgs.releaseTools.aggregate {
    name = "cardano-required-checks";
    constituents =
      let
        all = x: map (system: x.${system}) supportedSystems;
      in
    [
      (all jobsets.all-cardano-sl)
      (all jobsets.daedalus-bridge)
      jobsets.mainnet.connectScripts.wallet.x86_64-linux
      jobsets.tests.hlint
      jobsets.tests.shellcheck
      jobsets.tests.stylishHaskell
      jobsets.tests.swaggerSchemaValidation
    ];
  });
}
// (builtins.listToAttrs (map makeRelease [ "mainnet" "staging" ])))
