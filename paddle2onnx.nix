{
  lib,
  buildPythonPackage,
  fetchPypi,
  python,
  onnx,
  autoPatchelfHook,
  stdenv,
}:

let
  version = "2.1.0";
  pyShortVersion = "cp${builtins.replaceStrings [ "." ] [ "" ] python.pythonVersion}";

  platformInfo = {
    x86_64-linux = {
      platform = "manylinux_2_24_x86_64.manylinux_2_28_x86_64";
      hash = "sha256-f+8D1sQLvl4uvG6JWyW4hgrNKIA2ARlYhOj/7F/6EQk=";
    };
    aarch64-linux = {
      platform = "manylinux_2_24_aarch64.manylinux_2_28_aarch64";
      hash = "sha256-9M4I6xvidVOtvaZb/wHJZxOl0tCxIZBiv3xBB+lxKF8=";
    };
    x86_64-darwin = {
      platform = "macosx_12_0_universal2";
      hash = "sha256-DEXiT/kXTy500B6Ty8ypj6hMUDBJn4fzM9PU1kUrOwg=";
    };
    aarch64-darwin = {
      platform = "macosx_12_0_universal2";
      hash = "sha256-DEXiT/kXTy500B6Ty8ypj6hMUDBJn4fzM9PU1kUrOwg=";
    };
  };

  info = platformInfo.${stdenv.hostPlatform.system}
    or (throw "paddle2onnx: unsupported system ${stdenv.hostPlatform.system}");
in
buildPythonPackage {
  pname = "paddle2onnx";
  inherit version;
  format = "wheel";

  src = fetchPypi {
    pname = "paddle2onnx";
    inherit version;
    format = "wheel";
    dist = pyShortVersion;
    python = pyShortVersion;
    abi = pyShortVersion;
    inherit (info) platform hash;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  dependencies = [
    onnx
  ];

  meta = {
    description = "PaddlePaddle to ONNX model converter";
    homepage = "https://github.com/PaddlePaddle/Paddle2ONNX";
    changelog = "https://github.com/PaddlePaddle/Paddle2ONNX/releases/tag/v${version}";
    mainProgram = "paddle2onnx";
    license = lib.licenses.asl20;
  };
}
