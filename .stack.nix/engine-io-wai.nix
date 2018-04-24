{ compiler, flags ? {}, hsPkgs, pkgconfPkgs, pkgs, system }:
let
    _flags = {} // flags;
    in {
      flags = _flags;
      package = {
        specVersion = "1.10";
        identifier = {
          name = "engine-io-wai";
          version = "1.0.6";
        };
        license = "BSD-3-Clause";
        copyright = "";
        maintainer = "brandon@codedmart.com";
        author = "Brandon Martin";
        homepage = "http://github.com/ocharles/engine.io";
        url = "";
        synopsis = "";
        description = "This package provides an @engine-io@ @ServerAPI@ that is compatible with\n<https://hackage.haskell.org/package/wai/ Wai>.";
        buildType = "Simple";
      };
      components = {
        engine-io-wai = {
          depends  = [
            hsPkgs.base
            hsPkgs.engine-io
            hsPkgs.http-types
            hsPkgs.unordered-containers
            hsPkgs.wai
            hsPkgs.text
            hsPkgs.bytestring
            hsPkgs.websockets
            hsPkgs.wai-websockets
            hsPkgs.mtl
            hsPkgs.either
            hsPkgs.transformers
            hsPkgs.transformers-compat
            hsPkgs.attoparsec
          ];
        };
      };
    } // {
      src = pkgs.fetchgit {
        url = "https://github.com/serokell/engine.io.git";
        rev = "a594e402fd450f11ad60d09ddbd93db500000632";
        sha256 = null;
      };
      postUnpack = "sourceRoot+=/engine-io-wai; echo source root reset to \$sourceRoot";
    }