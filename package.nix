{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zstd,
  zlib,
  libcap,
  openssl,
}:

let
  version = "0.144.3";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0fm30klw2ljq1xyc9n8fb8yyqny2jb87i6c5w7amy1il5zq74w77";
    "aarch64-unknown-linux-musl" = "16kbva5267x325xxwcqzvyq4hypj2md9iz512s5h5aff4fjzqkdx";
    "x86_64-apple-darwin" = "18mavkmqpxmhi4ygld011sz27gybykndmczim9m6iq47488r20ca";
    "aarch64-apple-darwin" = "1dg208gsm3ldpj6dsflhbqbpv3dc1sx8r6a0wxv3ipaach9az6i4";
  };

  platform = platformMap.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  isLinux = stdenv.hostPlatform.isLinux;
  archive = if isLinux then
    "codex-${platform}-bundle.tar.zst"
  else
    "codex-${platform}.tar.gz";
  binary = if isLinux then "codex" else "codex-${platform}";
in

stdenv.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/${repo}/releases/download/rust-v${version}/${archive}";
    sha256 = hashes.${platform};
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals isLinux [
    autoPatchelfHook
    zstd
  ];

  buildInputs = lib.optionals isLinux [
    stdenv.cc.cc.lib
    zlib
    libcap
    openssl
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ${binary} $out/bin/codex
    chmod +x $out/bin/codex
    if [ -d codex-resources ]; then
      cp -r codex-resources $out/bin/
    fi

    runHook postInstall
  '';

  dontFixup = !isLinux;

  meta = {
    description = "OpenAI Codex CLI — an AI coding agent for your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/${repo}/releases/tag/rust-v${version}";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames platformMap;
    mainProgram = "codex";
  };
}
