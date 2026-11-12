# Development

Building, the checks and how the pinned commit moves. The reasons behind the
packaging are in [DESIGN.md](DESIGN.md).

## Commands

| Command | What it does |
|---|---|
| `nix develop` | Enter the lint and format shell |
| `nix flake check` | Build every scheduler and run the module evaluation check |
| `nix build .#scx-git` | Build the Rust schedulers |
| `nix build .#scx-git-full` | Build the full set, which is also the default package |

[.envrc](../.envrc) loads the same shell through direnv. Run `direnv allow`
once per clone.

## Checks

`module-eval-nixos` in [flake.nix](../flake.nix) evaluates
[module.nix](../module.nix) with the overlay applied. Its configuration sets
`scx-git.enable`, `services.scx-loader.enable` and
`services.scx-loader.config.default_sched = "scx_rusty"`.

The package has an install check of its own. It fails when the build produced
fewer than five `scx_*` binaries.

Upstream's tests are not run. [DESIGN.md](DESIGN.md) says why.

The dev shell, the formatter, the lint hooks and the remaining checks come from
`inputs.std.flakeModules.base`, the base module of
[nix-packaging-standard](https://github.com/Daaboulex/nix-packaging-standard)
that [flake.nix](../flake.nix) imports.

[.github/workflows/ci.yml](../.github/workflows/ci.yml) runs on a push to
`main` or `master`, on a pull request and on a manual dispatch. It calls the
standard's `package-ci` workflow.

## Updating the pinned commit

A scheduled GitHub Action tracks `sched-ext/scx` main, bumps the pinned commit,
regenerates the source and Cargo hashes, builds, and only lands the change if
it passes. Failures open an issue instead of merging.

Its settings are in [.github/update.json](../.github/update.json). It follows
commits on the `main` branch of `sched-ext/scx`, writes the version in the
`unstable-date` scheme, and regenerates `hash` and `cargoHash` in
[package.nix](../package.nix).

`cargoHash` is regenerated on every bump. The `Cargo.lock` of git main moves,
so the hash is not stable across revisions.

[.github/workflows/update.yml](../.github/workflows/update.yml) runs it daily
by default. Setting the repository variable `UPDATE_CADENCE` to `weekly` leaves
only the Sunday run. A manual dispatch always runs.

## Maintenance

[.github/workflows/maintenance.yml](../.github/workflows/maintenance.yml) is a
second scheduled workflow. It calls the standard's `package-maintenance`
workflow, which refreshes `flake.lock`.

It runs on Sundays by default. The repository variable `MAINTENANCE_CADENCE`
set to `biweekly` adds Wednesdays, and `daily` runs it every day.
