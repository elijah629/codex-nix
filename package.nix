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
  version = "0.132.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0jcas7xzc9zvgj98qbhgi5vq6xf5qzgqm46gz1ca468qnc364saw";
    "aarch64-unknown-linux-musl" = "0d60kzxz6mk3qyn5hpiafqrzk90z61bfj038cvvlbd07c038akng";
    "x86_64-apple-darwin" = "18cyz5rcqwlpi6l192wd405k3113mjp5n9d1ysmxpdpkyjdavb2q";
    "aarch64-apple-darwin" = "1kpxax1c4h0k87ym8dw07s6xvzzjmwfviywapchir512q40qw9bk";
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
