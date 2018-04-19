{ localLib ? import ./../../../../lib.nix
, config ? {}
, numCoreNodes ? 4
, system ? builtins.currentSystem
, pkgs ? import localLib.fetchNixPkgs { inherit system config; }
, gitrev ? "123456" # Dummy git revision to prevent mass rebuilds
, ghcRuntimeArgs ? "-N2 -qg -A1m -I0 -T"
, additionalNodeArgs ? ""
}:

with localLib;

let
  demo-cluster = iohkPkgs.demoCluster.override {
    inherit gitrev numCoreNodes;
    keepAlive = false;
  };
  executables =  {
    integration-test = "${iohkPkgs.cardano-sl-wallet-new}/bin/cardano-integration-test";
  };
  iohkPkgs = import ./../../../../default.nix { inherit config system pkgs gitrev; };
in pkgs.writeScript "integration-tests" ''
  source ${demo-cluster}
  ${executables.integration-test}
  EXIT_STATUS=$?
  stop_cardano
''
