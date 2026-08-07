# Package Management

Three package sources, in order of preference: home-manager (nix) > nix-darwin > Homebrew.

## 1. Home-Manager (Nixpkgs) — preferred

**Simple packages** (`home.packages`):
- `home.nix` — core/shared packages, with platform-specific lists via `lib.optionals isDarwin/isLinux`
- `work.nix` — work-related packages (zoom-us, slack, awscli2, etc.)
- `user.nix` — personal packages (deno, fonts, etc.; Linux-only: vscode, flatpak)

**Programs with config** (`programs.*`):
- `programs.nix` — ghostty, direnv, ripgrep, mergiraf, difftastic
- `user.nix` — vscode, gh, bash, neovim, git, starship
- `shell.nix` — 1password-shell-plugins, zsh, fish

**Custom derivations:**
- `openwhispr.nix` — custom package with its own derivation

## 2. Nix-Darwin (macOS system-level)

- `darwin/base.nix` — system packages and Homebrew module config
- `darwin/work.nix` — work-specific Homebrew brews and casks

## 3. Homebrew (via nix-darwin's homebrew module)

Used for macOS apps not well-supported by nixpkgs (e.g., `aws-vpn-client` cask in `darwin/work.nix`). Declared in nix files but installed by brew.

## Key Files

- `flake.nix` — flake inputs/outputs, entry point
- `home.nix` — main home-manager module, imports everything else
- `work.nix`, `user.nix`, `shell.nix`, `programs.nix` — domain-specific modules
- `darwin/base.nix`, `darwin/work.nix` — macOS-specific (nix-darwin + brew)

## Formatting

Before making any git commit, run `nixfmt` on all `.nix` files:

```bash
find . -name '*.nix' -not -path '*/\.*' | xargs nixfmt
```

## Adding Packages

When adding a new package, always ask whether it's work-specific. Work packages go in `work.nix`, personal/shared packages go in `home.nix` or `user.nix`.
