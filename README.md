# paddle-onnx

A Nix Flake that downloads pre-trained [PaddlePaddle](https://www.paddlepaddle.org.cn/) models and converts them to [ONNX](https://onnx.ai/) format using [paddle2onnx](https://github.com/PaddlePaddle/Paddle2ONNX).

## Models

| Package name | Description |
|---|---|
| `eslav-pp-ocrv5-mobile-rec` | Eslavian OCR v5 recognition (mobile) |
| `pp-lcnet-x1-0-doc-ori` | LCNet document orientation detection |
| `pp-ocrv5-mobile-det` | OCR v5 text detection (mobile) |
| `pp-ocrv5-mobile-rec` | OCR v5 text recognition (mobile) |
| `pp-ocrv5-server-det` | OCR v5 text detection (server) |
| `pp-ocrv5-server-rec` | OCR v5 text recognition (server) |

Models are sourced from the official PaddlePaddle model zoo (paddle3.0.0 inference models).

## Requirements

- [Nix](https://nixos.org/) with flakes enabled

## Usage

Build a specific model:

```bash
nix build .#pp-ocrv5-mobile-rec
```

Build all models into a single output:

```bash
nix build .#all
```

Each built model derivation contains:
- `model.onnx` — the converted ONNX model
- `config.yml` — original PaddlePaddle inference configuration

## Using in another flake

Add this flake as an input and call `lib.mkModels` with your `pkgs` instance to get model derivations built for the current system:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    paddle-onnx.url = "github:akiro-group/paddle-onnx";
  };

  outputs = { self, nixpkgs, flake-utils, paddle-onnx }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        models = paddle-onnx.lib.mkModels pkgs;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "my-app";
          buildInputs = [ models.pp-ocrv5-mobile-rec ];
        };
      }
    );
}
```

Model files are available via the `passthru.modelPath` attribute, which resolves to the per-model subdirectory:

```nix
models.pp-ocrv5-mobile-rec.passthru.modelPath
# => /nix/store/...-pp-ocrv5-mobile-rec-3.0.0/pp-ocrv5-mobile-rec
```

## Platforms

| Platform | Supported |
|---|---|
| `x86_64-linux` | Yes |
| `aarch64-linux` | Yes |
| `x86_64-darwin` | Yes |
| `aarch64-darwin` | Yes |

## paddle2onnx

The bundled `paddle2onnx` package (v2.1.0) is built from pre-compiled PyPI wheels with automatic platform detection. On Linux, dynamic library paths are fixed using `autoPatchelfHook`. On macOS, library paths are fixed using `install_name_tool`.
