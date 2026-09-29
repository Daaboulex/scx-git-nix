{
  description = "scx-git — bleeding-edge sched-ext schedulers (git main) packaged for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    std = {
      url = "github:Daaboulex/nix-packaging-standard?ref=v2.40.1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.git-hooks.follows = "git-hooks";
    };
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [ inputs.std.flakeModules.base ];

      flake.overlays =
        let
          glueOverlay = import ./overlay.nix;
          dir = ./overlays;
          names = if builtins.pathExists dir then builtins.attrNames (builtins.readDir dir) else [ ];
          fixOverlays = map (n: (import (dir + "/${n}")).overlay) (
            builtins.filter (n: inputs.nixpkgs.lib.hasSuffix ".nix" n) names
          );
        in
        {
          default = inputs.nixpkgs.lib.composeManyExtensions ([ glueOverlay ] ++ fixOverlays);
          probe = glueOverlay;
        };
      flake.nixosModules.default = import ./module.nix;

      perSystem =
        { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          packages.scx-git = pkgs.scx-git;
          packages.scx-git-full = pkgs.scx-git-full;
          packages.default = pkgs.scx-git-full;

          checks.module-eval-nixos = inputs.std.lib.nixosModuleCheck {
            inherit (inputs) nixpkgs;
            inherit system;
            overlays = [ self.overlays.default ];
            module = ./module.nix;
            config = {
              scx-git.enable = true;
              services.scx.enable = true;
              services.scx.scheduler = "scx_rusty";
            };
          };
        };
    };
}
