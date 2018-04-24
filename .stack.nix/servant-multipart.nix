{ compiler, flags ? {}, hsPkgs, pkgconfPkgs, pkgs, system }:
let
    _flags = {} // flags;
    in {
      flags = _flags;
      package = {
        specVersion = "1.10";
        identifier = {
          name = "servant-multipart";
          version = "0.11";
        };
        license = "BSD-3-Clause";
        copyright = "2016-2017 Alp Mestanogullari";
        maintainer = "alpmestan@gmail.com";
        author = "Alp Mestanogullari";
        homepage = "https://github.com/haskell-servant/servant-multipart#readme";
        url = "";
        synopsis = "multipart/form-data (e.g file upload) support for servant";
        description = "Please see README.md";
        buildType = "Simple";
      };
      components = {
        servant-multipart = {
          depends  = [
            hsPkgs.base
            hsPkgs.bytestring
            hsPkgs.directory
            hsPkgs.http-media
            hsPkgs.lens
            hsPkgs.resourcet
            hsPkgs.servant
            hsPkgs.servant-docs
            hsPkgs.servant-server
            hsPkgs.text
            hsPkgs.transformers
            hsPkgs.wai
            hsPkgs.wai-extra
          ];
        };
        exes = {
          upload = {
            depends  = [
              hsPkgs.base
              hsPkgs.http-client
              hsPkgs.bytestring
              hsPkgs.network
              hsPkgs.servant
              hsPkgs.servant-multipart
              hsPkgs.servant-server
              hsPkgs.text
              hsPkgs.transformers
              hsPkgs.warp
              hsPkgs.wai
            ];
          };
        };
      };
    } // {
      src = pkgs.fetchgit {
        url = "https://github.com/serokell/servant-multipart.git";
        rev = "e7de56b5f7c39f8dc473f1bbaf534bb7affc3cf4";
        sha256 = null;
      };
    }