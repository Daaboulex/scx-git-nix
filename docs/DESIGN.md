# Design

Why the packaging is built the way it is. The page to read first is the
[README](../README.md).

## Rust schedulers from git, C examples from nixpkgs

This flake packages the Rust userspace schedulers from `sched-ext/scx` at the
latest commit, rebuilt automatically as upstream advances. Those are the
schedulers that actually move.

The C example schedulers live in a separate, rarely changing repository,
`scx-c-examples`, and are not recommended for end users. They gain nothing from
following git, so they are pulled in from nixpkgs as `scx.cscheds`.

`scx-git-full` joins the two with `buildEnv` in [overlay.nix](../overlay.nix).
It is the git analogue of `pkgs.scx.full`: the full scheduler set is available
with a single git pin and no gaps. Its `passthru.schedulers` is the list of
`scx-git` followed by the list of `scx.cscheds`.

The upstream project is [sched-ext/scx](https://github.com/sched-ext/scx),
licensed GPL-2.0. What is tracked is git commits on its `main` branch.

## The module does one thing

[module.nix](../module.nix) sets `services.scx-loader.schedsPackages` when
`scx-git.enable` is on. The value is `pkgs.scx-git-full`, or `pkgs.scx-git`
when `scx-git.full` is `false`. It is set with `lib.mkForce`.

The module does not enable the loader and does not choose a scheduler. Those
stay with `services.scx-loader.enable` and
`services.scx-loader.config.default_sched`.

The module reads both packages from `pkgs`. That is why the overlay of this
flake has to be applied next to it.

## The scheduler set is not asserted

Git main adds and removes schedulers continuously. nixpkgs asserts an exact
scheduler set, which is correct for a pinned release, but here it would break
the package on every upstream scheduler change.

The install check in [package.nix](../package.nix) is a sanity check only. It
fails when the build produced fewer than five `scx_*` binaries, and otherwise
prints the ones it found.

## The scheduler name list is static

`passthru.schedulers` in [package.nix](../package.nix) is a list written by
hand. A NixOS module reads it at evaluation time, so it cannot be derived from
the build output.

The list is refreshed against upstream as needed. The build does not enforce
it.

## Helper binaries are removed

The build deletes `scx_arena_selftests`, `vmlinux_docify`, `xtask` and
`scx_forge_agent` from the output. They are helper and development binaries
that the package does not ship.

They are removed with `rm -f`. The set drifts on git main, and a helper that
upstream dropped must not fail the build.

## Tests are off

`doCheck` is `false` in [package.nix](../package.nix). Most of upstream's tests
read live CPU topology information, which the build sandbox lacks.

## Fixes the build carries

Two things differ from a plain build of upstream. Each one states when it can
be removed.

### clang 22 for the BPF schedulers

[overlays/bpf-clang-22.nix](../overlays/bpf-clang-22.nix) was added on
2026-09-29. It overrides `scx-git` to take `llvmPackages_22`, so the
`BPF_CLANG` the build hands to upstream's `build.rs` is clang 22.

The reason the file records: scx main refuses to build its cid-form schedulers
with a clang older than 22, which mishandles their arena memory, and the
default `llvmPackages` clang in nixpkgs is 21. The upstream code it points at
is
[bpf_builder.rs](https://github.com/sched-ext/scx/blob/a730d683cf32a087304c78df04078b5204359abc/rust/scx_cargo/src/bpf_builder.rs#L447-L476).

Its `dropWhenBuilds` names `scx-git`. The fix stays until `scx-git` builds
without it.

[flake.nix](../flake.nix) composes `overlays.default` from
[overlay.nix](../overlay.nix) and every `.nix` file under `overlays/`.
`overlays.probe` is [overlay.nix](../overlay.nix) alone, without the fixes.

### `__u128` in the vendored libbpf

The `prePatch` in [package.nix](../package.nix) applies
[libbpf-linux-types-u128.patch](../libbpf-linux-types-u128.patch) to the libbpf
that the `libbpf-sys` crate vendors. The patch adds the `__s128` and `__u128`
types to that libbpf's `include/linux/types.h`.

The reason is in commit `ef15c14` of this repository. The kernel headers in
nixpkgs moved to 7.3, whose arm64 `asm/sigcontext.h` uses `__u128`. scx bundles
`libbpf-sys` 1.7.0, whose own `include/linux/types.h` shadows the system one
without that type, so the build failed on aarch64.

libbpf added the type in its commit `f90a9c487`. The patch is a file in this
repository, not a fetch from GitHub, because GitHub rate-limits commit patch
URLs and builds failed with HTTP 429 (commit `a348e39`).

The build stops with a removal instruction in two cases: when it finds no
vendored `libbpf-sys`, and when the vendored libbpf already defines `__u128`.
The patch therefore cannot stay in place after it stopped being needed.
