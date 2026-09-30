{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  bubblewrap,
}:

let
  version = "0.159.2";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "sha256-ni0ppxO5RHiyQN7C8Q4RMkzQX6123EPnxjm9+KEzems=";
    "aarch64-unknown-linux-musl" = "sha256-BaUkpGPK334+Isf5I1OcDQt0w+eLH18fq1LlDm+zMS8=";
    "x86_64-apple-darwin" = "sha256-a5s4v61qyAGapqJD7jqxHT4iiJ6v1UWLA0TPIOeX5oA=";
    "aarch64-apple-darwin" = "sha256-OKr23OYwmf0QmIlI0Du8bAR0JTrvaWH8vmD40VSzkQE=";
  };

  platform = platformMap.${stdenvNoCC.hostPlatform.system}
    or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
  isLinux = stdenvNoCC.hostPlatform.isLinux;
in

stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/${repo}/releases/download/rust-v${version}/codex-package-${platform}.tar.gz";
    hash = hashes.${platform};
  };

  sourceRoot = ".";
  nativeBuildInputs = lib.optionals isLinux [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -R bin codex-package.json codex-path codex-resources "$out/"
    ${lib.optionalString isLinux ''
      wrapProgram "$out/bin/codex" \
        --prefix PATH : ${lib.makeBinPath [ bubblewrap ]}
    ''}

    runHook postInstall
  '';

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
