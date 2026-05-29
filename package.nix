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
  version = "0.135.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "09x3pad99r0wycgazi8vbcgkiazckmv7a7blkd7v6sr2536f65pv";
    "aarch64-unknown-linux-musl" = "08qwc5s8pyygk3nvkgxyndpqgr7g4a3pd7q4ar2wxi50hvx1vfkz";
    "x86_64-apple-darwin" = "1rf6pmyc5wl5bwq64avkd77zgqvg5fs88j9pz336bvhl8l6ay9ky";
    "aarch64-apple-darwin" = "0g5ksjb6kk910pazkjyjcliv6fdlsvc63dmar0a54s7bx2d55vmz";
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
