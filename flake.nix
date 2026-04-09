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
          src = builtins.fetchurl {
            url = "${baseUrl}/cyrillic_PP-OCRv5_mobile_rec_infer.tar";
            sha256 = "ef0c66f19ebe6849daf9aa7485e9253d2a8d851e165e208bf08ba68a620ae645";
          };
          outputHash = "sha256-Pl90W8sOFGf935TGJcXt2YLAWcri6+VfDkf5ZXvmr28=";
        };
        latin-pp-ocrv5-mobile-rec = {
          src = builtins.fetchurl {
            url = "${baseUrl}/latin_PP-OCRv5_mobile_rec_infer.tar";
            sha256 = "b23105a6a1ea38e32a97c5a0ddc7e8a9bbf541d8e47421e2c99e9ccabe29509c";
          };
          outputHash = "sha256-KFyDLqf+V0amt2NN/wpUms9mw9hGM+eYHRII3XzY1rk=";
        };
        en-pp-ocrv5-mobile-det = {
          src = builtins.fetchurl {
            url = "${baseUrl}/en_PP-OCRv5_mobile_rec_infer.tar";
            sha256 = "e595b4cf2ffad19fbb5a61ba345d63939577a3ab8717b6e5995642590c9101b4";
          };
          outputHash = "sha256-senkAmebyoicQ0lw9c9qNuWbTMiA992mzz734G9Hsr4=";
        };
        eslav-pp-ocrv5-mobile-rec = {
          src = builtins.fetchurl {
            url = "${baseUrl}/eslav_PP-OCRv5_mobile_rec_infer.tar";
            sha256 = "b9f70da0ca2bbc4d4cb7ba406a2d023061178437d6a930f07c8ca18c6c591839";
          };
          outputHash = "sha256-JVC3YVSOc5ClRrLrD7Q4BcrYZzeLtFatkVmYTZ8MNWI=";
        };
        pp-lcnet-x0-25-textline-ori = {
          src = builtins.fetchurl {
            url = "${baseUrl}/PP-LCNet_x0_25_textline_ori_infer.tar";
            sha256 = "268d9aea61461c3d4a5a32752e5b920e8af2ee0a002362f6ba5cd39638fa2c3a";
          };
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
          src = builtins.fetchurl {
            url = "${baseUrl}/PP-LCNet_x1_0_doc_ori_infer.tar";
            sha256 = "282337df5c41f7cdf8dacd5acf71fddfdc10218399f4b318463c17f4eae96c97";
          };
          outputHash = "sha256-8fIZLzE8MQDXAVHeSeGB9FgSjV5vPhnLjmGigie4Itw=";
        };
        pp-ocrv5-mobile-det = {
          src = builtins.fetchurl {
            url = "${baseUrl}/PP-OCRv5_mobile_det_infer.tar";
            sha256 = "50446e5d01ac2a73d5319c89513281f6578414c888c602f9af13f93feefffc58";
          };
          outputHash = "sha256-8laQoLO5ZER+1T1m7TxK2oQv8Jvb2unWoFeUR2/OsWo=";
        };
        pp-ocrv5-mobile-rec = {
          src = builtins.fetchurl {
            url = "${baseUrl}/PP-OCRv5_mobile_rec_infer.tar";
            sha256 = "566b9512b34e34a9f0db54d87b51fa5a0b9ed2cf1ab7e49728cc0b8b5a64f414";
          };
          outputHash = "sha256-IJvx9G3F4Pz1Ye+zJ90pX69Z3SpDDPpyqMDfQ5V5CSk=";
        };
        pp-ocrv5-server-det = {
          src = builtins.fetchurl {
            url = "${baseUrl}/PP-OCRv5_server_det_infer.tar";
            sha256 = "22a33e0ba6a21425ea4192da03bf4395c9a0c67902bd924b7328fc859073045d";
          };
          outputHash = "sha256-kXOaDvXzPOxEysnGsvckoHyys68nYlFM5X3unZA94H4=";
        };
        pp-ocrv5-server-rec = {
          src = builtins.fetchurl {
            url = "${baseUrl}/PP-OCRv5_server_rec_infer.tar";
            sha256 = "d99be2ffd348943ab52876179168be4fb5b14f5f0812f2ae4c76d89ec2ea750a";
          };
          outputHash = "sha256-GruBSgCVA1Ww81IR3Ty2IZFFBwG2A8egXmc0Q77YvUM=";
        };
        uvdoc = {
          src = builtins.fetchurl {
            url = "${baseUrl}/UVDoc_infer.tar";
            sha256 = "15d79c6bcbf738b7e132eedff6ed57c7e834c73cbc140a1fff8fd8ab9c2a35b9";
          };
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

      mkPublicModels = pkgs: builtins.mapAttrs (mkModel pkgs) models;

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
