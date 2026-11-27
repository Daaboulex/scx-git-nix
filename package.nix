{
  lib,
  rustPlatform,
  llvmPackages,
  pkg-config,
  elfutils,
  zlib,
  zstd,
  fetchFromGitHub,
  protobuf,
  libseccomp,
}:
let
  helpers = [
    "scx_arena_libarena_selftests"
    "scx_arena_selftests"
    "vmlinux_docify"
    "xtask"
  ];
in
rustPlatform.buildRustPackage (
  finalAttrs:
  let
    workspaceAtRev = builtins.fetchTree {
      type = "github";
      inherit (finalAttrs.src) owner repo rev;
    };
    manifest = member: lib.importTOML "${workspaceAtRev}/${member}/Cargo.toml";
    binariesOf =
      member:
      let
        crate = manifest member;
      in
      if crate ? bin then
        map (bin: bin.name) crate.bin
      else
        lib.optional (builtins.pathExists "${workspaceAtRev}/${member}/src/main.rs") crate.package.name;
    members = (lib.importTOML "${workspaceAtRev}/Cargo.toml").workspace.members;
  in
  {
    pname = "scx-git";
    # Auto-updated by the standard's updater (versionScheme: unstable-date).
    version = "1.1.5-unstable-2026-11-26";

    src = fetchFromGitHub {
      owner = "sched-ext";
      repo = "scx";
      rev = "0df97416ebd5d5ea7d1b87a74289af66909ce41e";
      hash = "sha256-JOC/LQd6yPcRBsd6aHo9yHJOh8MQpdsnWo3wM7UDPTo=";
    };

    # Regenerated on every bump by the updater (build-extract). The Cargo.lock
    # of git main moves, so this is not stable across revisions.
    cargoHash = "sha256-lOV88lCytLfxb1pqXJ504JYgIjqr0GGZBBkY2oviR38=";

    nativeBuildInputs = [
      pkg-config
      rustPlatform.bindgenHook
      protobuf
    ];

    buildInputs = [
      elfutils
      zlib
      zstd
      libseccomp
    ];

    env = {
      # build.rs compiles the BPF schedulers with clang.
      BPF_CLANG = lib.getExe llvmPackages.clang;
      RUSTFLAGS = lib.concatStringsSep " " [
        "-C relocation-model=pic"
        "-C link-args=-lelf"
        "-C link-args=-lz"
        "-C link-args=-lzstd"
      ];
    };

    hardeningDisable = [
      "zerocallusedregs"
    ];

    # Most tests read live CPU-topology info, which the sandbox lacks.
    doCheck = false;

    postInstall = ''
      rm ${lib.concatMapStringsSep " " (helper: "$out/bin/${helper}") helpers}
    '';

    __structuredAttrs = true;

    shippedBinaries = lib.subtractLists helpers (lib.concatMap binariesOf members);

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      cd $out/bin
      found=(scx_*)
      if (( ''${#found[@]} < 5 )); then
        echo "Expected several scx_* schedulers; found only: ''${found[*]:-none}"
        exit 1
      fi
      echo "Built ''${#found[@]} schedulers: ''${found[*]}"
      missing=$(comm -23 <(printf '%s\n' "''${shippedBinaries[@]}" | sort) <(printf '%s\n' * | sort))
      undeclared=$(comm -13 <(printf '%s\n' "''${shippedBinaries[@]}" | sort) <(printf '%s\n' * | sort))
      if [ -n "$missing$undeclared" ]; then
        echo "$out/bin differs from the binaries upstream's Cargo workspace declares, less the helpers postInstall removes"
        echo "declared but not installed: ''${missing:-none}"
        echo "installed but not declared: ''${undeclared:-none}"
        exit 1
      fi
      export SCX_SYSFS_PREFIX=$TMPDIR/one-cpu-sysfs
      cpus=$SCX_SYSFS_PREFIX/sys/devices/system/cpu
      mkdir -p $cpus/cpu0/topology
      echo 0 > $cpus/online
      for id in core_id physical_package_id cluster_id; do echo 0 > $cpus/cpu0/topology/$id; done
      for b in *; do
        ./$b --version > /dev/null || ./$b --help > /dev/null || {
          echo "$b exits non-zero on both --version and --help, run in a sandbox with no /sys and the one-CPU topology under $SCX_SYSFS_PREFIX"
          exit 1
        }
      done
      runHook postInstallCheck
    '';

    passthru.schedulers = lib.concatMap binariesOf (lib.filter (lib.hasPrefix "scheds/") members);

    meta = {
      description = "Sched-ext Rust userspace schedulers (git main)";
      longDescription = ''
        Bleeding-edge sched_ext userspace schedulers built from the tip of
        sched-ext/scx main.

        ::: {.note}
        Sched-ext schedulers require a Linux kernel 6.12 or newer with sched_ext
        enabled. Use the latest kernel for best compatibility.
        :::
      '';
      homepage = "https://github.com/sched-ext/scx";
      changelog = "https://github.com/sched-ext/scx/commits/main";
      license = lib.licenses.gpl2Only;
      platforms = lib.platforms.linux;
    };
  }
)
