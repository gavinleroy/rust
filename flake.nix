{
  description = "Rust + WASM Support Nightly-2024-05-20";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
  flake-utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-darwin"
  ] (system:
  let
    overlays = [ (import rust-overlay) ];
    pkgs = import nixpkgs {
      inherit system overlays;
    };

    rustc-host = if system == "x86_64-linux"
                 then "x86_64-unknown-linux-gnu"
                 else
                   if system == "aarch64-darwin"
                   then "aarch64-apple-darwin"
                   else throw "unsupported system ${system}";

    wasm-rustc = pkgs.stdenv.mkDerivation {
      name = "wasm-nightly-2024-05-20";
      src = pkgs.fetchFromGitHub {
        owner = "gavinleroy";
        repo = "rust";
        rev = "daf2ff4ea2eff086c8b8fedf1f97a8d01cf7725e";
        sha256 = "sha256-+EisNzocztvCus3wVdfD3nplqnDMDCenPVq9pGlVwyI=";
        fetchSubmodules = true;
        leaveDotGit = true;
      };

      nativeBuildInputs = with pkgs; [
        llvmPackages_latest.llvm
        llvmPackages_latest.lld
        libiconv
        rust-bin.stable.latest.default
        pkg-config
        python3
        cmake
        ninja
        clang
        curl
        cacert
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
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        RUST_BACKTRACE = "1";
      };

      #dontConfigure = true;
      phases = ["unpackPhase" "installPhase"];

      installPhase = ''
        export CARGO_HOME=$TMP/.cargo
        export DESTDIR=$out
        python3 x.py install --stage 1 --host ${rustc-host} --target ${rustc-host}
      '';
    };
  in {
    packages = {
      default = wasm-rustc;
    };
  });
}
