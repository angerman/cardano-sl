{ compiler, flags ? {}, hsPkgs, pkgconfPkgs, pkgs, system }:
let
    _flags = {} // flags;
    in {
      flags = _flags;
      package = {
        specVersion = "1.18";
        identifier = {
          name = "log-warper";
          version = "1.8.0";
        };
        license = "MIT";
        copyright = "2016-2017 Serokell";
        maintainer = "Serokell <hi@serokell.io>";
        author = "@serokell";
        homepage = "https://github.com/serokell/log-warper";
        url = "";
        synopsis = "Flexible, configurable, monadic and pretty logging";
        description = "This package implements nice and featureful wrapper around hslogger library.";
        buildType = "Simple";
      };
      components = {
        log-warper = {
          depends  = [
            hsPkgs.aeson
            hsPkgs.ansi-terminal
            hsPkgs.base
            hsPkgs.containers
            hsPkgs.deepseq
            hsPkgs.directory
            hsPkgs.dlist
            hsPkgs.errors
            hsPkgs.exceptions
            hsPkgs.extra
            hsPkgs.filepath
            hsPkgs.fmt
            hsPkgs.formatting
            hsPkgs.hashable
            hsPkgs.lens
            hsPkgs.monad-control
            hsPkgs.monad-loops
            hsPkgs.mmorph
            hsPkgs.mtl
            hsPkgs.network
            hsPkgs.text
            hsPkgs.text-format
            hsPkgs.time
            hsPkgs.transformers
            hsPkgs.transformers-base
            hsPkgs.universum
            hsPkgs.unordered-containers
            hsPkgs.vector
            hsPkgs.yaml
          ] ++ pkgs.lib.optional (!system.isWindows) hsPkgs.unix;
        };
        tests = {
          log-test = {
            depends  = [
              hsPkgs.async
              hsPkgs.base
              hsPkgs.data-default
              hsPkgs.directory
              hsPkgs.filepath
              hsPkgs.hspec
              hsPkgs.HUnit
              hsPkgs.lens
              hsPkgs.log-warper
              hsPkgs.QuickCheck
              hsPkgs.universum
              hsPkgs.unordered-containers
            ];
          };
        };
      };
    } // {
      src = pkgs.fetchgit {
        url = "https://github.com/serokell/log-warper.git";
        rev = "7f95c6990ef93a289678755cb1db71c2a4ecdfb5";
        sha256 = null;
      };
    }