{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  bubblewrap,
}:

let
  version = "0.151.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "sha256-bjWsYLhsDox/i895e+i5IgYZn2JTIAtm/wVHJ2+M+lw=";
    "aarch64-unknown-linux-musl" = "sha256-xkrW5PgmCVUqNwaTZbUFKO9J6YauqySlOHgaGKQCdz0=";
    "x86_64-apple-darwin" = "sha256-6DSOEZLxVe2yG9uq8yMcIyEIeRC7FHKxMG+U+xEIrXA=";
    "aarch64-apple-darwin" = "sha256-y25466gMG8MQpTP28cbJSDd3M7wG+eg3lJM04Eq96cY=";
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
