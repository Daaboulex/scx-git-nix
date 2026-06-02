# scx-git-nix

<!-- BEGIN generated:badges -->
[![CI](https://github.com/Daaboulex/scx-git-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/Daaboulex/scx-git-nix/actions/workflows/ci.yml)
[![NixOS unstable](https://img.shields.io/badge/NixOS-unstable-78C0E8?logo=nixos&logoColor=white)](https://nixos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
<!-- END generated:badges -->

Bleeding-edge [sched-ext](https://github.com/sched-ext/scx) schedulers built from the tip of `main`, packaged for NixOS — the sched_ext analogue of [mesa-git-nix](https://github.com/Daaboulex/mesa-git-nix). Always the latest `scx_lavd`, `scx_rusty`, `scx_layered`, `scx_flash`, `scx_bpfland` and friends.

<!-- BEGIN generated:upstream -->
## Upstream

| | |
|---|---|
| **Project** | [sched-ext/scx](https://github.com/sched-ext/scx) |
| **License** | GPL-2.0 |
| **Tracked** | Git commits (main branch) |

<!-- END generated:upstream -->

## What Is This?

A Nix flake that packages the **Rust userspace schedulers** from `sched-ext/scx` at the latest commit, rebuilt automatically as upstream advances. The C *example* schedulers (a separate, rarely-changing `scx-c-examples` repo, not recommended for end users) are pulled in from nixpkgs so the full scheduler set is available with a single git pin.

## What's Included

- `scx-git` — the git-main Rust schedulers (`scx_rusty`, `scx_lavd`, `scx_layered`, `scx_bpfland`, `scx_flash`, `scx_rustland`, …).
- `scx-git-full` *(default)* — `scx-git` plus nixpkgs' C example schedulers, the git analogue of `pkgs.scx.full`. No gaps in the available scheduler set.
- An overlay exposing `pkgs.scx-git` / `pkgs.scx-git-full`.
- A NixOS module that points `services.scx` at the git schedulers.

## Requirements

- A Linux kernel **6.12 or newer** with `sched_ext` enabled (e.g. recent CachyOS, or `boot.kernelPackages = pkgs.linuxPackages_latest`). The package builds on any kernel; the schedulers only *run* on a sched_ext kernel.
- `x86_64-linux` (the Rust schedulers bundle x86-only asm).

<!-- BEGIN generated:installation -->
## Installation

Add the flake and apply the overlay + module:

```nix
{
  inputs.scx-git.url = "github:Daaboulex/scx-git-nix";

  # in your NixOS configuration:
  imports = [ inputs.scx-git.nixosModules.default ];
  nixpkgs.overlays = [ inputs.scx-git.overlays.default ];

  scx-git.enable = true;        # point services.scx at the git schedulers
  services.scx = {
    enable = true;
    scheduler = "scx_rusty";    # or scx_lavd, scx_layered, scx_bpfland, …
  };
}
```

<!-- END generated:installation -->

## Usage

### Run a scheduler ad-hoc

Schedulers must run as root on a `sched_ext` kernel (6.12+):

```bash
nix build github:Daaboulex/scx-git-nix#scx-git
sudo ./result/bin/scx_rusty        # or scx_lavd, scx_layered, scx_bpfland, …
```

### As a package

```nix
environment.systemPackages = [ inputs.scx-git.packages.${system}.scx-git-full ];
```

`scx-git.full = false;` selects the Rust schedulers only.

## Updates

A scheduled GitHub Action tracks `sched-ext/scx` main, bumps the pinned commit, regenerates the source and Cargo hashes, builds, and only lands the change if it passes. Failures open an issue instead of merging.

## Development

```bash
nix develop          # lint/format shell
nix flake check      # build every scheduler + the module-eval check
nix build .#scx-git  # the Rust schedulers
```

## Credits

All scheduler work is by the [sched-ext](https://github.com/sched-ext) project and contributors. This repo only packages it for Nix.

## License

Packaging is MIT (see [LICENSE](./LICENSE)); the schedulers themselves are GPL-2.0, upstream.

<!-- BEGIN generated:footer -->
---

*Maintained as part of the [Daaboulex](https://github.com/Daaboulex) NixOS ecosystem.*
<!-- END generated:footer -->
