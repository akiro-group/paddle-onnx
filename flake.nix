{
  description = "PaddlePaddle to ONNX model converter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        lib = pkgs.lib;

        paddle2onnx = pkgs.python312Packages.callPackage ./paddle2onnx.nix { };

        baseUrl = "https://paddle-model-ecology.bj.bcebos.com/paddlex/official_inference_model/paddle3.0.0";

        models = {
          eslav-pp-ocrv5-mobile-rec = {
            fetchName = "eslav_PP-OCRv5_mobile_rec";
            sha256 = "sha256-ufcNoMorvE1Mt7pAai0CMGEXhDfWqTDwfIyhjGxZGDk=";
          };
          pp-lcnet-x1-0-doc-ori = {
            fetchName = "PP-LCNet_x1_0_doc_ori";
            sha256 = "sha256-KCM331xB98342s1az3H939wQIYOZ9LMYRjwX9OrpbJc=";
          };
          pp-ocrv5-mobile-det = {
            fetchName = "PP-OCRv5_mobile_det";
            sha256 = "sha256-UERuXQGsKnPVMZyJUTKB9leEFMiIxgL5rxP5P+7//Fg=";
          };
          pp-ocrv5-mobile-rec = {
            fetchName = "PP-OCRv5_mobile_rec";
            sha256 = "sha256-VmuVErNONKnw21TYe1H6Wgue0s8at+SXKMwLi1pk9BQ=";
          };
          pp-ocrv5-server-det = {
            fetchName = "PP-OCRv5_server_det";
            sha256 = "sha256-IqM+C6aiFCXqQZLaA79DlcmgxnkCvZJLcyj8hZBzBF0=";
          };
          pp-ocrv5-server-rec = {
            fetchName = "PP-OCRv5_server_rec";
            sha256 = "sha256-2Zvi/9NIlDq1KHYXkWi+T7WxT18IEvKuTHbYnsLqdQo=";
          };
        };

        hasCuda = pkgs.config.cudaSupport or false;

        mkOnnxModel = name: {
          fetchName,
          sha256,
          modelFilename ? "inference.json",
          paramsFilename ? "inference.pdiparams",
        }:
          let
            tarName = "${fetchName}_infer";
            drv = pkgs.stdenvNoCC.mkDerivation {
              pname = name;
              version = "3.0.0";

              src = pkgs.fetchurl {
                url = "${baseUrl}/${tarName}.tar";
                inherit sha256;
              };

              nativeBuildInputs = [
                pkgs.ccache
                paddle2onnx
              ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                pkgs.darwin.system_cmds
              ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                pkgs.procps
              ];

              env = lib.optionalAttrs hasCuda {
                LD_LIBRARY_PATH = "${pkgs.cudaPackages.cudatoolkit}/lib";
                CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
              };

              unpackPhase = ''
                tar xf $src
              '';

              buildPhase = ''
                paddle2onnx \
                  --model_dir "${tarName}" \
                  --model_filename "${modelFilename}" \
                  --params_filename "${paramsFilename}" \
                  --save_file "${name}/model.onnx" \
                  --optimize_tool None
              '';

              installPhase = ''
                mkdir -p $out/${name}
                cp ${name}/model.onnx $out/${name}/
                cp ${tarName}/inference.yml $out/${name}/config.yml
              '';

              passthru.modelPath = "${drv}/${name}";

              meta = {
                description = "ONNX export of ${fetchName}";
              };
            };
          in drv;

      in
      {
        packages =
          (lib.mapAttrs (name: attrs: mkOnnxModel name attrs) models)
          // {
            all = pkgs.symlinkJoin {
              name = "paddle-onnx-models-all";
              paths = lib.attrValues (lib.mapAttrs (name: attrs: mkOnnxModel name attrs) models);
            };
          };
      }
    );
}
