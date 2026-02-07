{
  description = "Python development environment with ML/AI libraries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true; # Neccesary for some ML packages
          };
        };

        python = pkgs.python313;
        
        pythonEnv = python.withPackages (ps: with ps; [
          # ML/AI frameworks
          ultralytics
          transformers
          torch
          torchvision
          
          # ONNX ecosystem
          onnx
          onnxscript
          onnxruntime
          
          # Data science essentials
          numpy
          pandas
          matplotlib
          pillow
          opencv4
          
          # Development tools
          ipython
          jupyter
          black
          pylint
          pytest
          
          # Utilities
          requests
          tqdm
        ]);

        # ML/vision libraries
        systemLibraries = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          libGL
          glib
          fontconfig
          freetype
        ];

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pythonEnv
            pkgs.git
            pkgs.ruff
          ];

          buildInputs = systemLibraries;

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath systemLibraries;

          shellHook = ''
            echo "🐍 Python ML/AI Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            python --version
            echo ""
            echo "📦 Available packages:"
            echo "  • ultralytics (YOLO)"
            echo "  • transformers (Hugging Face)"
            echo "  • torch + torchvision"
            echo "  • onnx + onnxruntime"
            echo "  • opencv, numpy, pandas, matplotlib"
            echo ""
            echo "🛠️  Tools: ipython, jupyter, black, pylint, pytest, ruff"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit or ""}
          '';

          PYTHON_ENV = "nix-ml-dev";
          
          # Avoid pip install in home
          PIP_PREFIX = "$(pwd)/_build/pip_packages";
          PYTHONPATH = "$(pwd)/_build/pip_packages/${python.sitePackages}:$PYTHONPATH";
          PATH = "$(pwd)/_build/pip_packages/bin:$PATH";
        };
      }
    );
}
