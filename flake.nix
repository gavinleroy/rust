{
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
  in {
    devShell = with pkgs; mkShell {
      buildInputs = [
        clang
        ninja
        cmake

        llvmPackages_latest.llvm
        llvmPackages_latest.lld

        rust-bin.stable.latest.default
      ] ++ lib.optional stdenv.isDarwin [
        darwin.apple_sdk.frameworks.SystemConfiguration
      ];

      RUSTC_LINKER = "${pkgs.llvmPackages.clangUseLLVM}/bin/clang";
    };
  });
}
