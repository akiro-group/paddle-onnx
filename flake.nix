{
  description = "PaddlePaddle to ONNX model converter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      baseUrl = "https://paddle-model-ecology.bj.bcebos.com/paddlex/official_inference_model/paddle3.0.0";

      models = {
        cyrillic-pp-ocrv5-mobile-det = {
          fetchName = "cyrillic_PP-OCRv5_mobile_rec";
          sha256 = "sha256-7wxm8Z6+aEna+ap0heklPSqNhR4WXiCL8IumimIK5kU=";
          outputHash = "sha256-Pl90W8sOFGf935TGJcXt2YLAWcri6+VfDkf5ZXvmr28=";
        };
        latin-pp-ocrv5-mobile-rec = {
          fetchName = "latin_PP-OCRv5_mobile_rec";
          sha256 = "sha256-sjEFpqHqOOMql8Wg3cfoqbv1QdjkdCHiyZ6cyr4pUJw=";
          outputHash = "sha256-KFyDLqf+V0amt2NN/wpUms9mw9hGM+eYHRII3XzY1rk=";
        };
        en-pp-ocrv5-mobile-det = {
          fetchName = "en_PP-OCRv5_mobile_rec";
          sha256 = "sha256-5ZW0zy/60Z+7WmG6NF1jk5V3o6uHF7blmVZCWQyRAbQ=";
          outputHash = "sha256-senkAmebyoicQ0lw9c9qNuWbTMiA992mzz734G9Hsr4=";
        };
        eslav-pp-ocrv5-mobile-rec = {
          fetchName = "eslav_PP-OCRv5_mobile_rec";
          sha256 = "sha256-ufcNoMorvE1Mt7pAai0CMGEXhDfWqTDwfIyhjGxZGDk=";
          outputHash = "sha256-JVC3YVSOc5ClRrLrD7Q4BcrYZzeLtFatkVmYTZ8MNWI=";
        };
        pp-lcnet-x0-25-textline-ori = {
          fetchName = "PP-LCNet_x0_25_textline_ori";
          sha256 = "sha256-Jo2a6mFGHD1KWjJ1LluSDory7goAI2L2ulzTljj6LDo=";
          outputHash = "sha256-3ACW4zQnLcVERKeV9K1q85hCpZTEgDNSLGf9U/S8gXQ=";
        };
        pp-lcnet-x1-0-doc-ori = {
          fetchName = "PP-LCNet_x1_0_doc_ori";
          sha256 = "sha256-KCM331xB98342s1az3H939wQIYOZ9LMYRjwX9OrpbJc=";
          outputHash = "sha256-8fIZLzE8MQDXAVHeSeGB9FgSjV5vPhnLjmGigie4Itw=";
        };
        pp-ocrv5-mobile-det = {
          fetchName = "PP-OCRv5_mobile_det";
          sha256 = "sha256-UERuXQGsKnPVMZyJUTKB9leEFMiIxgL5rxP5P+7//Fg=";
          outputHash = "sha256-8laQoLO5ZER+1T1m7TxK2oQv8Jvb2unWoFeUR2/OsWo=";
        };
        pp-ocrv5-mobile-rec = {
          fetchName = "PP-OCRv5_mobile_rec";
          sha256 = "sha256-VmuVErNONKnw21TYe1H6Wgue0s8at+SXKMwLi1pk9BQ=";
          outputHash = "sha256-IJvx9G3F4Pz1Ye+zJ90pX69Z3SpDDPpyqMDfQ5V5CSk=";
        };
        pp-ocrv5-server-det = {
          fetchName = "PP-OCRv5_server_det";
          sha256 = "sha256-IqM+C6aiFCXqQZLaA79DlcmgxnkCvZJLcyj8hZBzBF0=";
          outputHash = "sha256-kXOaDvXzPOxEysnGsvckoHyys68nYlFM5X3unZA94H4=";
        };
        pp-ocrv5-server-rec = {
          fetchName = "PP-OCRv5_server_rec";
          sha256 = "sha256-2Zvi/9NIlDq1KHYXkWi+T7WxT18IEvKuTHbYnsLqdQo=";
          outputHash = "sha256-GruBSgCVA1Ww81IR3Ty2IZFFBwG2A8egXmc0Q77YvUM=";
        };
        uvdoc = {
          fetchName = "UVDoc";
          sha256 = "sha256-Fdeca8v3OLfhMu7f9u1Xx+g0xzy8FAof/4/Yq5wqNbk=";
          outputHash = "sha256-0hCUNHnngEfXnzgxgUb7xBTaXsOTnILFGOAVyMn3M80=";
        };
      };

      mkModels = pkgs:
        let
          lib = pkgs.lib;
          paddle2onnx = pkgs.python312Packages.callPackage ./paddle2onnx.nix { };
          hasCuda = pkgs.config.cudaSupport or false;

          mkOnnxModel = name: {
            fetchName,
            sha256,
            outputHash,
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
                  mkdir -p $out
                  cp ${name}/model.onnx $out/model.onnx
                  cp ${tarName}/inference.yml $out/config.yml
                '';

                inherit outputHash;
                outputHashAlgo = "sha256";
                outputHashMode = "recursive";

                meta = {
                  description = "ONNX export of ${fetchName}";
                };
              };
            in drv;
        in
        lib.mapAttrs mkOnnxModel models;

    in
    {
      lib.mkModels = mkModels;

    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        modelDerivations = mkModels pkgs;
      in
      {
        packages = modelDerivations;
      }
    );
}
