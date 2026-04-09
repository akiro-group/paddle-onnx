{
  description = "PaddlePaddle to ONNX model converter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      baseUrl = "https://paddle-model-ecology.bj.bcebos.com/paddlex/official_inference_model/paddle3.0.0";

      models = {
        cyrillic-pp-ocrv5-mobile-det = {
          url = "${baseUrl}/cyrillic_PP-OCRv5_mobile_rec_infer.tar";
          hash = "sha256-7wxm8Z6+aEna+ap0heklPSqNhR4WXiCL8IumimIK5kU=";
          outputHash = "sha256-Pl90W8sOFGf935TGJcXt2YLAWcri6+VfDkf5ZXvmr28=";
        };
        latin-pp-ocrv5-mobile-rec = {
          url = "${baseUrl}/latin_PP-OCRv5_mobile_rec_infer.tar";
          hash = "sha256-sjEFpqHqOOMql8Wg3cfoqbv1QdjkdCHiyZ6cyr4pUJw=";
          outputHash = "sha256-KFyDLqf+V0amt2NN/wpUms9mw9hGM+eYHRII3XzY1rk=";
        };
        en-pp-ocrv5-mobile-det = {
          url = "${baseUrl}/en_PP-OCRv5_mobile_rec_infer.tar";
          hash = "sha256-5ZW0zy/60Z+7WmG6NF1jk5V3o6uHF7blmVZCWQyRAbQ=";
          outputHash = "sha256-senkAmebyoicQ0lw9c9qNuWbTMiA992mzz734G9Hsr4=";
        };
        eslav-pp-ocrv5-mobile-rec = {
          url = "${baseUrl}/eslav_PP-OCRv5_mobile_rec_infer.tar";
          hash = "sha256-ufcNoMorvE1Mt7pAai0CMGEXhDfWqTDwfIyhjGxZGDk=";
          outputHash = "sha256-JVC3YVSOc5ClRrLrD7Q4BcrYZzeLtFatkVmYTZ8MNWI=";
        };
        pp-lcnet-x0-25-textline-ori = {
          url = "${baseUrl}/PP-LCNet_x0_25_textline_ori_infer.tar";
          hash = "sha256-Jo2a6mFGHD1KWjJ1LluSDory7goAI2L2ulzTljj6LDo=";
          outputHash = "sha256-Dg5cvewZ817b6r1GQhyhv+KJIxHVdSxZVYVfFvZkxtM=";
          inputShape = {
            x = [
              1
              3
              80
              160
            ];
          };
        };
        pp-lcnet-x1-0-doc-ori = {
          url = "${baseUrl}/PP-LCNet_x1_0_doc_ori_infer.tar";
          hash = "sha256-KCM331xB98342s1az3H939wQIYOZ9LMYRjwX9OrpbJc=";
          outputHash = "sha256-8fIZLzE8MQDXAVHeSeGB9FgSjV5vPhnLjmGigie4Itw=";
        };
        pp-ocrv5-mobile-det = {
          url = "${baseUrl}/PP-OCRv5_mobile_det_infer.tar";
          hash = "sha256-UERuXQGsKnPVMZyJUTKB9leEFMiIxgL5rxP5P+7//Fg=";
          outputHash = "sha256-8laQoLO5ZER+1T1m7TxK2oQv8Jvb2unWoFeUR2/OsWo=";
        };
        pp-ocrv5-mobile-rec = {
          url = "${baseUrl}/PP-OCRv5_mobile_rec_infer.tar";
          hash = "sha256-VmuVErNONKnw21TYe1H6Wgue0s8at+SXKMwLi1pk9BQ=";
          outputHash = "sha256-IJvx9G3F4Pz1Ye+zJ90pX69Z3SpDDPpyqMDfQ5V5CSk=";
        };
        pp-ocrv5-server-det = {
          url = "${baseUrl}/PP-OCRv5_server_det_infer.tar";
          hash = "sha256-IqM+C6aiFCXqQZLaA79DlcmgxnkCvZJLcyj8hZBzBF0=";
          outputHash = "sha256-kXOaDvXzPOxEysnGsvckoHyys68nYlFM5X3unZA94H4=";
        };
        pp-ocrv5-server-rec = {
          url = "${baseUrl}/PP-OCRv5_server_rec_infer.tar";
          hash = "sha256-2Zvi/9NIlDq1KHYXkWi+T7WxT18IEvKuTHbYnsLqdQo=";
          outputHash = "sha256-GruBSgCVA1Ww81IR3Ty2IZFFBwG2A8egXmc0Q77YvUM=";
        };
        uvdoc = {
          url = "${baseUrl}/UVDoc_infer.tar";
          hash = "sha256-Fdeca8v3OLfhMu7f9u1Xx+g0xzy8FAof/4/Yq5wqNbk=";
          outputHash = "sha256-jJR909VvOX8eAyc8q5/Bc5KavFRYZRad8V243abG5AI==";
          patches = [ ./patches/0001-uvdoc-rename-img-to-image.patch ];
        };
      };

      mkModel =
        pkgs: name:
        {
          src,
          outputHash,
          modelFilename ? "inference.json",
          paramsFilename ? "inference.pdiparams",
          inputShape ? null,
          patches ? [ ],
        }:
        let
          lib = pkgs.lib;
          paddle2onnx = pkgs.python312Packages.callPackage ./modules/paddle2onnx.nix {
            paddlepaddle = pkgs.python312Packages.paddlepaddle.override { cudaSupport = false; };
          };
          hasCuda = pkgs.config.cudaSupport or false;
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = name;
          version = "3.0.0";

          inherit src patches;

          nativeBuildInputs = [
            pkgs.ccache
            paddle2onnx
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
            pkgs.darwin.system_cmds
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            pkgs.procps
          ];

          env = lib.optionalAttrs hasCuda {
            LD_LIBRARY_PATH = "${pkgs.cudaPackages.cudatoolkit}/lib";
            CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
          };

          buildPhase = ''
            paddle2onnx \
              --model_dir . \
              --model_filename "${modelFilename}" \
              --params_filename "${paramsFilename}" \
              --save_file model.onnx \
              --optimize_tool None
          ''
          + lib.optionalString (inputShape != null) ''
            python3 -m paddle2onnx.optimize \
              --input_model model.onnx \
              --output_model model.onnx \
              --input_shape_dict '${builtins.toJSON inputShape}'
          '';

          installPhase = ''
            mkdir -p $out
            cp model.onnx $out/model.onnx
            cp inference.yml $out/config.yml
          '';

          inherit outputHash;
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";

          meta = {
            description = "ONNX export of ${name}";
          };
        };

      mkPublicModels =
        pkgs:
        builtins.mapAttrs (
          name: attrs:
          mkModel pkgs name (
            (builtins.removeAttrs attrs [
              "url"
              "hash"
            ])
            // {
              src = pkgs.fetchurl { inherit (attrs) url hash; };
            }
          )
        ) models;

    in
    {
      lib = {
        inherit models mkModel mkPublicModels;
      };

    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        modelDerivations = mkPublicModels pkgs;
      in
      {
        packages = modelDerivations;
      }
    );
}
