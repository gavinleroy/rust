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
        rev = "112d9190fe059e062b8d628fa528f9555003a5c3";
        sha256 = "sha256-5Qb7YdbgEREK9oRQtO63W92pgb3m3L0K/3paAEXQFbA";
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
      };

      dontConfigure = true;

      buildPhase = ''
        export CARGO_HOME=$TMP/.cargo/
        python3 ./x.py build --host=${rustc-host} --target={rustc-host}
      '';

      installPhase = ''
        python3 ./x.py install --host=${rustc-host} --target={rustc-host}
        python3 ./x.py install miri --host=${rustc-host} --target={rustc-host}
        cp -r build/${rustc-host} $out/
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
