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
  version = "0.142.5";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "03d64gv6ag03vc5vgi9cfxcnjfhddykvp4gbll3471b0zpkp8406";
    "aarch64-unknown-linux-musl" = "17rv24vay3mfljcsfxkn70l2h8vsdghmm3zpgcl45kiy0xn03ciz";
    "x86_64-apple-darwin" = "0q1rgg4ap492l67bgvi4fm2604chdm7728xxdbgz3qsz5crs6s9r";
    "aarch64-apple-darwin" = "01x7wg91k4hrh6vi51qzi1v7j3n4x2mpppawapxrqp3kcacv2mki";
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
