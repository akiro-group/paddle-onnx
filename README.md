# paddle-onnx

A Nix Flake that downloads pre-trained [PaddlePaddle](https://www.paddlepaddle.org.cn/) models and converts them to [ONNX](https://onnx.ai/) format using [paddle2onnx](https://github.com/PaddlePaddle/Paddle2ONNX).

## Models

| Package name | Description |
|---|---|
| `cyrillic-pp-ocrv5-mobile-det` | Cyrillic OCR v5 recognition (mobile) |
| `en-pp-ocrv5-mobile-det` | English OCR v5 recognition (mobile) |
| `eslav-pp-ocrv5-mobile-rec` | East Slavic OCR v5 recognition (mobile) |
| `latin-pp-ocrv5-mobile-rec` | Latin OCR v5 recognition (mobile) |
| `pp-lcnet-x0-25-textline-ori` | LCNet x0.25 text line orientation detection |
| `pp-lcnet-x1-0-doc-ori` | LCNet x1.0 document orientation detection |
| `pp-ocrv5-mobile-det` | OCR v5 text detection (mobile) |
| `pp-ocrv5-mobile-rec` | OCR v5 text recognition (mobile) |
| `pp-ocrv5-server-det` | OCR v5 text detection (server) |
| `pp-ocrv5-server-rec` | OCR v5 text recognition (server) |
| `pp-ocrv6-medium-det` | OCR v6 text detection (medium) |
| `pp-ocrv6-medium-rec` | OCR v6 text recognition (medium, multilingual) |
| `pp-ocrv6-small-det` | OCR v6 text detection (small) |
| `pp-ocrv6-small-rec` | OCR v6 text recognition (small, multilingual) |
| `pp-ocrv6-tiny-det` | OCR v6 text detection (tiny) |
| `pp-ocrv6-tiny-rec` | OCR v6 text recognition (tiny, multilingual) |
| `uvdoc` | UVDoc document unwarping |

Models are sourced from the official PaddlePaddle model zoo (paddle3.0.0 inference models).

### PP-OCRv6 notes

PP-OCRv6 (PaddleOCR 3.7) ships three size tiers, `tiny`, `small` and `medium`, which replace the
`mobile`/`server` naming of PP-OCRv5. There are no language-specific v6 variants: every v6
recognition model uses a single multilingual dictionary (about 18.7k classes for `small`/`medium`,
6.9k for `tiny`) covering Latin, Greek and CJK scripts. It contains no Cyrillic characters, so the
v5 `cyrillic`/`eslav` models remain the only option for those scripts.

Tensor names and shapes are unchanged from v5: input `x` (`[N, 3, H, W]` for detection,
`[N, 3, 48, W]` for recognition), output `fetch_name_0`.

Detection post-processing defaults changed between v5 and v6, so read them from the bundled
`config.yml` instead of assuming the v5 values:

| Setting | PP-OCRv5 | PP-OCRv6 |
|---|---|---|
| `thresh` | 0.3 | 0.2 |
| `box_thresh` | 0.6 | 0.45 (`tiny`: 0.4) |
| `unclip_ratio` | 1.5 | 1.4 |
| `max_candidates` | 1000 | 3000 |

`DetResizeForTest` in the v6 config no longer specifies `resize_long: 960`; choose the resize
policy explicitly in your pipeline.

## Requirements

- [Nix](https://nixos.org/) with flakes enabled

## Usage

Build a specific model:

```bash
nix build .#pp-ocrv5-mobile-rec
```

Each built model derivation contains:
- `model.onnx` — converted ONNX model
- `config.yml` — original PaddlePaddle inference configuration

## Using in another flake

Add this flake as an input and call `lib.mkPublicModels` with your `pkgs` instance to get model derivations built for the current system:

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
        models = paddle-onnx.lib.mkPublicModels pkgs;
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

## Platforms

| Platform | Supported |
|---|---|
| `x86_64-linux` | Yes |
| `aarch64-linux` | Yes |
| `x86_64-darwin` | Yes |
| `aarch64-darwin` | Yes |

## paddle2onnx

The bundled `paddle2onnx` package (v2.1.0) is built from pre-compiled PyPI wheels with automatic platform detection. On Linux, dynamic library paths are fixed using `autoPatchelfHook`. On macOS, library paths are fixed using `install_name_tool`.
