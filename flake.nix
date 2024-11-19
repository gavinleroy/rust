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
        rev = "371844e7d2b4c6f65cfc4ffec14bda5310298a71";
        sha256 = "sha256-QhctanPi/E3fBaGflEvnguAq35cAjTff14Ky2CzztYE=";
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

      dontConfigure = true;

      #python3 ./x.py dist rustc-dev --host=${rustc-host} --target=${rustc-host}
      buildPhase = ''
        export CARGO_HOME=$TMP/.cargo/
        python3 ./x.py install --host=${rustc-host} --target=${rustc-host}
        python3 ./x.py build rustc std cargo miri cargo-miri --host=${rustc-host} --target=${rustc-host}
      '';


      installPhase = ''
        mkdir -p $out/bin
        mkdir -p $out/lib
        mv build/${rustc-host}/stage1/bin $out/
        mv build/${rustc-host}/stage1/lib $out/

        rm $out/lib/rustlib/src/rust
        mkdir -p $out/lib/rustlib/src/rust

        rm $out/lib/rustlib/rustc-src/rust
        mkdir -p $out/lib/rustlib/rustc-src/rust

        cp Cargo.lock $out/lib/rustlib/src/rust/
        mv library $out/lib/rustlib/src/rust/
        mv src $out/lib/rustlib/src/rust/

        mv Cargo.lock $out/lib/rustlib/rustc-src/rust/
        mv compiler $out/lib/rustlib/rustc-src/rust/
      '';
    };
  in {
    packages = {
      default = wasm-rustc;
    };
  });
}
