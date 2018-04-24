let
  cardano-pkgs = hsPkgs: {
    cardano-sl-ssc         = ./ssc/cardano-sl-ssc.nix;
    cardano-sl-crypto      = ./crypto/cardano-sl-crypto.nix;
    cardano-sl-crypto-test = ./crypto/tests/cardano-sl-crypto-test.nix;
    cardano-sl-infra       = ./infra/cardano-sl-infra.nix;
    cardano-sl-tools       = ./tools/cardano-sl-tools.nix;
    cardano-sl-core        = ./core/cardano-sl-core.nix;
    cardano-sl-wallet-new  = ./wallet-new/cardano-sl-wallet-new.nix;
    cardano-sl-update      = ./update/cardano-sl-update.nix;
    cardano-sl-util        = ./util/cardano-sl-util.nix;
    cardano-sl-auxx        = ./auxx/cardano-sl-auxx.nix;
    cardano-sl-networking  = ./networking/cardano-sl-networking.nix;
    cardano-sl-explorer    = ./explorer/cardano-sl-explorer.nix;
    cardano-sl-delegation  = ./delegation/cardano-sl-delegation.nix;
    cardano-sl-lrc         = ./lrc/cardano-sl-lrc.nix;
    cardano-sl-generator   = ./generator/cardano-sl-generator.nix;
    cardano-sl-wallet      = ./wallet/cardano-sl-wallet.nix;
    cardano-sl             = ./lib/cardano-sl.nix;
    cardano-sl-db          = ./db/cardano-sl-db.nix;
    cardano-sl-txp         = ./txp/cardano-sl-txp.nix;
    cardano-sl-binary      = ./binary/cardano-sl-binary.nix;
    cardano-sl-node        = ./node/cardano-sl-node.nix;
    cardano-sl-client      = ./client/cardano-sl-client.nix;
    cardano-sl-block       = ./block/cardano-sl-block.nix;
  };

  extraHackageDeps = hsPkgs: {
    "ekg-core" = hsPkgs."ekg-core"."0.1.1.3";
    "transformers" = hsPkgs."transformers"."0.5.5.0";
    "universum" = hsPkgs."universum"."0.9.0";
    "serokell-util" = hsPkgs."serokell-util"."0.5.2";
    "pvss" = hsPkgs."pvss"."0.2.0";
    "base58-bytestring" = hsPkgs."base58-bytestring"."0.1.0";
    "concurrent-extra" = hsPkgs."concurrent-extra"."0.7.0.10";
    #"directory" = hsPkgs."directory"."1.3.1.0";
    "servant" = hsPkgs."servant"."0.12";
    "servant-client" = hsPkgs."servant-client"."0.12";
    "servant-client-core" = hsPkgs."servant-client-core"."0.12";
    "servant-docs" = hsPkgs."servant-docs"."0.11.1";
    "servant-swagger" = hsPkgs."servant-swagger"."1.1.4";
    "servant-swagger-ui" = hsPkgs."servant-swagger-ui"."0.2.4.3.4.0";
    "servant-blaze" = hsPkgs."servant-blaze"."0.7.1";
    "servant-quickcheck" = hsPkgs."servant-quickcheck"."0.0.4";
    "ether" = hsPkgs."ether"."0.5.1.0";
    "pipes-interleave" = hsPkgs."pipes-interleave"."1.1.1";
    "generic-arbitrary" = hsPkgs."generic-arbitrary"."0.1.0";
    "happy" = hsPkgs."happy"."1.19.5";
    "entropy" = hsPkgs."entropy"."0.3.7";
    "fmt" = hsPkgs."fmt"."0.5.0.0";
    "systemd" = hsPkgs."systemd"."1.1.2";
    "tabl" = hsPkgs."tabl"."1.0.3";
    "ekg-statsd" = hsPkgs."ekg-statsd"."0.2.2.0";
    "fgl" = hsPkgs."fgl"."5.5.3.1";
    "megaparsec" = hsPkgs."megaparsec"."6.2.0";
    "parser-combinators" = hsPkgs."parser-combinators"."0.2.0";
    "loc" = hsPkgs."loc"."0.1.3.1";
    "lens-sop" = hsPkgs."lens-sop"."0.2.0.2";
    "json-sop" = hsPkgs."json-sop"."0.2.0.3";
    "servant-generic" = hsPkgs."servant-generic"."0.1.0.1";
    "conduit" = hsPkgs."conduit"."1.3.0";
    "conduit-extra" = hsPkgs."conduit-extra"."1.3.0";
    "mono-traversable" = hsPkgs."mono-traversable"."1.0.8.1";
    "resourcet" = hsPkgs."resourcet"."1.2.0";
    "yaml" = hsPkgs."yaml"."0.8.28";
    "lzma" = hsPkgs."lzma"."0.0.0.3";
    "lzma-clib" = hsPkgs."lzma-clib"."5.2.2";
    "lzma-conduit" = hsPkgs."lzma-conduit"."1.2.1";
    "wai-extra" = hsPkgs."wai-extra"."3.0.22.0";
    "typed-process" = hsPkgs."typed-process"."0.2.1.0";
    "unliftio" = hsPkgs."unliftio"."0.2.4.0";
    "unliftio-core" = hsPkgs."unliftio-core"."0.1.1.0";
    "http-conduit" = hsPkgs."http-conduit"."2.3.0";
    "simple-sendfile" = hsPkgs."simple-sendfile"."0.2.27";
    "basement" = hsPkgs."basement"."0.0.6";
    "foundation" = hsPkgs."foundation"."0.0.19";
    "memory" = hsPkgs."memory"."0.14.14";
    "criterion" = hsPkgs."criterion"."1.3.0.0";
    "gauge" = hsPkgs."gauge"."0.2.1";
    "statistics" = hsPkgs."statistics"."0.14.0.2";
    "validation" = hsPkgs."validation"."0.6.1";
    "swagger2" = hsPkgs."swagger2"."2.2.1";
  };

  extraSrcDeps = hsPkgs: {
    cborg                      = ./ext-deps/cborg/cborg/cborg.nix;
    cborg-json                 = ./ext-deps/cborg/cborg-json/cborg-json.nix;
    binary-serialise-cbor      = ./ext-deps/cborg/binary-serialise-cbor/binary-serialise-cbor.nix;
    serialise                  = ./ext-deps/cborg/serialise/serialise.nix;
    cbor-tool                  = ./ext-deps/cborg/cbor-tool/cbor-tool.nix;
    ed25519                    = ./ext-deps/hs-ed25519/ed25519.nix;
    network-transport-tcp      = ./ext-deps/network-transport-tcp/network-transport-tcp.nix;
    log-warper                 = ./ext-deps/log-warper/log-warper.nix;
    servant-multipart          = ./ext-deps/servant-multipart/servant-multipart.nix;
    acid-state                 = ./ext-deps/acid-state/acid-state.nix;
    kademlia                   = ./ext-deps/kademlia/kademlia.nix;
    plutus-prototype           = ./ext-deps/plutus-prototype/plutus-prototype.nix;
    cardano-crypto             = ./ext-deps/cardano-crypto/cardano-crypto.nix;
    time-units                 = ./ext-deps/time-units/time-units.nix;
    network-transport          = ./ext-deps/network-transport/network-transport.nix;
    canonical-json             = ./ext-deps/canonical-json/canonical-json.nix;
    servant-client             = ./ext-deps/servant/servant-client/servant-client.nix;
    servant-client-core        = ./ext-deps/servant/servant-client-core/servant-client-core.nix;
    servant                    = ./ext-deps/servant/servant/servant.nix;
    tutorial                   = ./ext-deps/servant/doc/tutorial/tutorial.nix;
    servant-server             = ./ext-deps/servant/servant-server/servant-server.nix;
    servant-foreign            = ./ext-deps/servant/servant-foreign/servant-foreign.nix;
    servant-docs               = ./ext-deps/servant/servant-docs/servant-docs.nix;
    cardano-report-server      = ./ext-deps/cardano-report-server/cardano-report-server.nix;
    engine-io-yesod            = ./ext-deps/engine.io/engine-io-yesod/engine-io-yesod.nix;
    engine-io                  = ./ext-deps/engine.io/engine-io/engine-io.nix;
    chat                       = ./ext-deps/engine.io/examples/chat/chat.nix;
    latency                    = ./ext-deps/engine.io/examples/latency/latency.nix;
    binary-example             = ./ext-deps/engine.io/examples/binary/binary-example.nix;
    socket-io                  = ./ext-deps/engine.io/socket-io/socket-io.nix;
    engine-io-snap             = ./ext-deps/engine.io/engine-io-snap/engine-io-snap.nix;
    engine-io-wai              = ./ext-deps/engine.io/engine-io-wai/engine-io-wai.nix;
    cryptonite                 = ./ext-deps/cryptonite/cryptonite.nix;
    dns                        = ./ext-deps/dns/dns.nix;
    rocksdb-haskell-ng         = ./ext-deps/rocksdb-haskell-ng/rocksdb-haskell-ng.nix;
    network-transport-inmemory = ./ext-deps/network-transport-inmemory/network-transport-inmemory.nix;
  };


  overlay = self: super: {
    haskellPackages = (import <stackage>).lts-9_1
      { extraDeps = hsPkgs: (extraHackageDeps hsPkgs // extraSrcDeps hsPkgs // cardano-pkgs hsPkgs); };
  };

  pkgs = import <nixpkgs> { overlays = [ overlay ]; };
  # haskell = import <haskell>;
  # inherit (haskell.compat) driver host-map;


  # toGenericPackage = extraPkgs: args: name: raw-expr:
  #   let expr = driver { cabalexpr = raw-expr;
  #            pkgs = pkgs // { haskellPackages = pkgs.haskellPackages
  #                                            // extraPkgs; };
  #            inherit (host-map pkgs.stdenv) os arch; };
  #    in pkgs.haskellPackages.callPackage expr args;

  # cardano-pkgs = let p = pkgs.lib.mapAttrs (toGenericPackage cardano-pkgs {}) (cardano-pkgs-raw // extra-deps-raw); in p;

  mkLocal = drv: path: pkgs.haskell.lib.overrideCabal drv (drv: { src = path; });

in with pkgs.haskellPackages;
# pkgs.lib.mapAttrs (_: x: callPackage x {})
pkgs.haskellPackages.override {
  overrides = self: super: {
    # FIXME: this doesn't work yet. Overridable logic
    #        is missing.
  };
}
