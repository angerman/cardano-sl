{ compiler, flags ? {}, hsPkgs, pkgconfPkgs, pkgs, system }:
let
    _flags = {} // flags;
    in {
      flags = _flags;
      package = {
        specVersion = "1.10";
        identifier = {
          name = "acid-state";
          version = "0.14.2";
        };
        license = "LicenseRef-PublicDomain";
        copyright = "";
        maintainer = "Lemmih <lemmih@gmail.com>";
        author = "David Himmelstrup";
        homepage = "http://acid-state.seize.it/";
        url = "";
        synopsis = "Add ACID guarantees to any serializable Haskell data structure.";
        description = "Use regular Haskell data structures as your database and get stronger ACID guarantees than most RDBMS offer.";
        buildType = "Simple";
      };
      components = {
        acid-state = {
          depends  = [
            hsPkgs.array
            hsPkgs.base
            hsPkgs.bytestring
            hsPkgs.cereal
            hsPkgs.containers
            hsPkgs.extensible-exceptions
            hsPkgs.safecopy
            hsPkgs.stm
            hsPkgs.directory
            hsPkgs.filelock
            hsPkgs.filepath
            hsPkgs.mtl
            hsPkgs.network
            hsPkgs.template-haskell
            hsPkgs.th-expand-syns
          ] ++ (if system.isWindows
            then [ hsPkgs.Win32 ]
            else [ hsPkgs.unix ]);
        };
        benchmarks = {
          loading-benchmark = {
            depends  = [
              hsPkgs.random
              hsPkgs.directory
              hsPkgs.system-fileio
              hsPkgs.system-filepath
              hsPkgs.criterion
              hsPkgs.mtl
              hsPkgs.base
              hsPkgs.acid-state
            ];
          };
        };
      };
    } // {
      src = pkgs.fetchgit {
        url = "https://github.com/serokell/acid-state.git";
        rev = "9a8af2440d655e14b802639b0b363be2ffb5a32a";
        sha256 = null;
      };
    }