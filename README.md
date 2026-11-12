# sched-ext schedulers from git main (Nix)

The [sched-ext](https://github.com/sched-ext/scx) schedulers, built from
upstream's `main` branch and packaged for NixOS. It is for a NixOS system that
should run schedulers such as `scx_lavd`, `scx_rusty`, `scx_layered`,
`scx_flash` and `scx_bpfland` at upstream's latest commit.

All scheduler work is by the [sched-ext](https://github.com/sched-ext) project
and its contributors. This repository only packages it for Nix.

## Does it work

The flake builds from source for `x86_64-linux` and `aarch64-linux`, and it
follows nixpkgs `nixos-unstable`. Upstream scx is architecture-portable.

A scheduler only runs on a Linux kernel 6.12 or newer with `sched_ext` enabled.
A recent CachyOS kernel is one, and so is
`boot.kernelPackages = pkgs.linuxPackages_latest`. The package itself builds on
any kernel.

Untested: upstream's own tests are switched off in the build. The checks here
build the packages and evaluate the module, and none of them starts a scheduler
on a running kernel.

## What you get

- `scx-git` holds the Rust schedulers from git main, among them `scx_rusty`,
  `scx_lavd`, `scx_layered`, `scx_bpfland`, `scx_flash` and `scx_rustland`.
- `scx-git-full` is the default package. It is `scx-git` plus the C example
  schedulers from nixpkgs, the git analogue of `pkgs.scx.full`.
- An overlay adds both as `pkgs.scx-git` and `pkgs.scx-git-full`.
- A NixOS module points `services.scx-loader` at the git schedulers.

## Install

Add the flake:

```nix
{
  inputs.scx-git.url = "github:Daaboulex/scx-git-nix";
}
```

Then import the module, apply the overlay and switch it on:

```nix
{
  imports = [ inputs.scx-git.nixosModules.default ];
  nixpkgs.overlays = [ inputs.scx-git.overlays.default ];

  scx-git.enable = true;
  services.scx-loader = {
    enable = true;
    config.default_sched = "scx_rusty";
  };
}
```

`scx-git.enable` only swaps the schedulers that `services.scx-loader` runs. You
still enable the loader yourself and name the scheduler in
`config.default_sched`, for example `scx_rusty`, `scx_lavd` or `scx_bpfland`.
The overlay is required, because the module takes the packages from `pkgs`.

## Options you are likely to set

| Option | What it is for |
|---|---|
| `scx-git.enable` | Point `services.scx-loader` at the git schedulers |
| `scx-git.full` | On by default. Set it to `false` for the Rust schedulers only |

Every option, with its type and default: [docs/OPTIONS.md](docs/OPTIONS.md).

## Without the module

To try a scheduler without installing anything, build the package and run one
binary. A scheduler must run as root on a `sched_ext` kernel.

```bash
nix build github:Daaboulex/scx-git-nix#scx-git
sudo ./result/bin/scx_rusty
```

To install the schedulers as a plain package:

```nix
environment.systemPackages = [ inputs.scx-git.packages.${system}.scx-git-full ];
```

## Updates

A scheduled GitHub Action follows `sched-ext/scx` main and moves the pinned
commit. The change lands only if it builds. A failure opens an issue instead.

## Known limits

- The package builds on any kernel, but the schedulers only run on a
  `sched_ext` kernel.
- The set of schedulers is whatever upstream's main builds at the pinned
  commit. Upstream adds and removes schedulers, and the build does not hold the
  set fixed.
- The scheduler names the package declares are a list kept by hand. The build
  does not compare it with the binaries it produced.
- The C example schedulers in `scx-git-full` come from nixpkgs, not from git
  main, and are not recommended for end users.
- The module forces `services.scx-loader.schedsPackages`, so a plain setting of
  that option elsewhere in your configuration is ignored.
- Four helper binaries are removed from the package: `scx_arena_selftests`,
  `vmlinux_docify`, `xtask` and `scx_forge_agent`.

## More

- [docs/DESIGN.md](docs/DESIGN.md): why the Rust schedulers come from git and
  the C examples from nixpkgs, why the scheduler set is not fixed, the two
  fixes the build carries
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md): building, the checks, how the
  pinned commit is updated
- [SECURITY.md](SECURITY.md): how to report a vulnerability

## License

Packaging is MIT (see [LICENSE](./LICENSE)); the schedulers themselves are GPL-2.0, upstream. `scx-git` declares `meta.license` GPL-2.0-only and `scx-git-full` declares no `meta.license`.
