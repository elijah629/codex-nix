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
  version = "0.144.4";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "00lh8dm7vx9lxcjnix49qpk5zyp2hkk052fry9j5cfdp4c4ww70y";
    "aarch64-unknown-linux-musl" = "1ycfzh37qgrh2bjhq8b58nc6amdhpqa711i24mcja4hy0v15500n";
    "x86_64-apple-darwin" = "13hqwvsm68gmgl411abzwxw7hlh36gm627fng93isqj62a9s8ki7";
    "aarch64-apple-darwin" = "07irk4v34f6wfmr8mz58y7ivlfh83k1ad8ly3pdzj0hk92d9dj3p";
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
