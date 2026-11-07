{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.scx-git;
in
{
  options.scx-git = {
    enable = lib.mkEnableOption "git-latest sched-ext schedulers for the services.scx-loader daemon";

    full = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Use the complete scheduler set (git-main Rust schedulers plus nixpkgs'
        C example schedulers). Set to false for the Rust schedulers only.
      '';
    };
  };

  # Only swaps the schedulers services.scx-loader runs; the user still enables
  # `services.scx-loader` and picks `config.default_sched`. Requires this
  # flake's overlay so `pkgs.scx-git*` resolve (see README).
  config = lib.mkIf cfg.enable {
    services.scx-loader.schedsPackages = lib.mkForce [
      (if cfg.full then pkgs.scx-git-full else pkgs.scx-git)
    ];
  };
}
