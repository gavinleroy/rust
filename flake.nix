{
  description = "Rust + WASM Support Nightly-2024-05-20";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
  flake-utils.lib.eachDefaultSystem (system:
  let
    overlays = [ (import rust-overlay) ];
    pkgs = import nixpkgs {
      inherit system overlays;
    };

    wasm-rustc = pkgs.stdenv.mkDerivation {
      name = "wasm-nightly-2024-05-20";
      src = ./.;

      nativeBuildInputs = with pkgs; [
        llvmPackages_latest.llvm
        llvmPackages_latest.lld
        rust-bin.stable.latest.default

        pkg-config
        python3
        cmake
        ninja
        clang
        curl
        git
      ] ++ lib.optional stdenv.isDarwin [
        darwin.apple_sdk.frameworks.SystemConfiguration
      ];

      # TODO: don't think I need these...maybe though
      buildInputs = with pkgs; [
        openssl libxml2 zlib
      ];

      env = {
        RUSTC_LINKER = "${pkgs.llvmPackages.clangUseLLVM}/bin/clang";
      };

      dontConfigure = true;

      buildPhase = ''
        python3 ./x.py install
      '';

      installPhase = ''
        mkdir -p $out/bin
        mkdir -p $out/lib
        cp -r build/${system}/stage1/* $out/
        chmod +x $out/bin/*
      '';
    };
  in {
    # devShell = with pkgs; mkShell {
    #   buildInputs = [
    #     clang
    #     ninja
    #     cmake
    #     llvmPackages_latest.llvm
    #     llvmPackages_latest.lld
    #     rust-bin.stable.latest.default
    #   ] ++ lib.optional stdenv.isDarwin [
    #     darwin.apple_sdk.frameworks.SystemConfiguration
    #   ];
    #   RUSTC_LINKER = "${pkgs.llvmPackages.clangUseLLVM}/bin/clang";
    # };

    packages = {
      default = wasm-rustc;
    };
  });
}
