# codex-nix

Nix flake for [OpenAI Codex CLI](https://github.com/openai/codex) (the Rust CLI, `codex-rs`) — an AI coding agent for your terminal.

Packages the latest official pre-built binaries so you can use `codex` declaratively on NixOS, nix-darwin, and Home Manager without building from source.

## Quick Start

```bash
nix run github:SecBear/codex-nix -- --version
nix profile install github:SecBear/codex-nix
```

## Using as a Flake Input

```nix
{
  inputs.codex-nix.url = "github:SecBear/codex-nix";

  outputs = { nixpkgs, codex-nix, ... }: { ... };
}
```

### nix-darwin / NixOS

```nix
{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.codex-nix.packages.${pkgs.system}.default
  ];
}
```

### Home Manager

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.codex-nix.packages.${pkgs.system}.default
  ];
}
```

## Platforms

| Platform | Architecture | Status |
|----------|-------------|--------|
| macOS    | aarch64 (Apple Silicon) | Supported |
| macOS    | x86_64 | Supported |
| Linux    | x86_64 | Supported |
| Linux    | aarch64 | Supported |

## Updates

CI checks for new releases hourly. When a new version is detected,
it fetches updated hashes for all platforms, opens a PR, and auto-merges once CI passes.

One command updates version plus all four platform hashes. It downloads upstream's
small checksum manifest, not every platform archive, then changes `package.nix`
only after all checks pass:

```bash
./scripts/update.sh          # update to latest
./scripts/update.sh --check  # check only
./scripts/update.sh 0.105.0  # specific version
```

Linux builds add Nix's `bubblewrap` to Codex's `PATH`. Official full release
packages also include `codex-code-mode-host`, bundled sandbox resources, `rg`,
and `zsh`; these stay beside Codex in the Nix output.

## Related

- [openai/codex](https://github.com/openai/codex) — upstream project
