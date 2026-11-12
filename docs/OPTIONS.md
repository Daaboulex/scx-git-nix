# Options

Every option the modules of this flake declare. This file is generated from the module sources: change a description there, then run `nix run .#std-write-option-reference`.

## NixOS module

Declared in [module.nix](../module.nix).

### `scx-git.enable`

Whether to enable git-latest sched-ext schedulers for the services.scx-loader daemon.

- Type: boolean
- Default: `false`

### `scx-git.full`

Use the complete scheduler set (git-main Rust schedulers plus nixpkgs'
C example schedulers). Set to false for the Rust schedulers only.

- Type: boolean
- Default: `true`
