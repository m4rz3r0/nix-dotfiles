{
  description = "Rust flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        
        rust-toolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" ];
          targets = [ "x86_64-unknown-linux-gnu" ];
        };

        # Library dependencies for runtime linking
        libraries = with pkgs; [
          wayland
          libxkbcommon
          vulkan-loader
          libGL
          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
          fontconfig
          freetype
          dbus
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            # Rust toolchain
            rust-toolchain

            # Build tools
            pkgs.pkg-config
            pkgs.eza
            pkgs.fd
          ];

          buildInputs = [
            # Build and runtime libraries
            pkgs.openssl
          ] ++ libraries;

          # Set up library paths automatically
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libraries;

          shellHook = ''
            alias ls=eza
            alias find=fd
          '';
        };
      }
    );
}
