final: _prev: {
  # Git-main sched-ext Rust schedulers.
  scx-git = final.callPackage ./package.nix { };

  # Complete scheduler set, the git-main analogue of nixpkgs `scx.full`:
  # the git Rust schedulers (which actually move) plus nixpkgs' C example
  # schedulers (a separate, rarely-changing upstream repo that does not
  # benefit from git-latest). One git pin, no gaps in available schedulers.
  scx-git-full = final.buildEnv {
    name = "scx-git-full-${final.scx-git.version}";
    paths = [
      final.scx-git
      final.scx.cscheds
    ];
    passthru.schedulers = final.scx-git.passthru.schedulers ++ final.scx.cscheds.passthru.schedulers;
    meta = {
      description = "Sched-ext schedulers — git-main Rust + nixpkgs C examples";
      homepage = "https://github.com/sched-ext/scx";
    };
  };
}
