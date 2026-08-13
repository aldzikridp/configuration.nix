# AGENTS.md

NixOS + Home Manager configuration for `EVA-02`.

## Architecture
- **Entry point**: `flake.nix`
- **System config**: `configuration.nix` and modules in `module/`
- **User config**: `home/home.nix` (Home Manager)
- **Custom packages**: `pkgs/`

## Key Commands
- **Check configuration**: `nix flake check`
- **Apply configuration**: `sudo nixos-rebuild switch --flake .#EVA-02`
- **Documentation**: `man <command>`

## Constraints & Conventions
- **Apply Config**: Do NOT apply configuration without user permission or explicit request.
- **Immutable Users**: `users.mutableUsers = false`. All user changes must be declarative via Nix/Home Manager.
- **User**: `master-x`
- **System**: `EVA-02`
- **Timezone**: `Asia/Jakarta`
- **State Version**: `23.05`

## Documentation
- Read documentation before planning.
- When you need to search docs, use Context7.

