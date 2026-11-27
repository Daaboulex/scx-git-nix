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
  openssl,
}:
rustPlatform.buildRustPackage (_finalAttrs: {
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
    openssl # scx_forge_agent links openssl-sys via native-tls (reqwest)
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
    rm $out/bin/scx_arena_selftests $out/bin/vmlinux_docify $out/bin/xtask
  '';

  __structuredAttrs = true;

  # git main adds/removes schedulers continuously, so do NOT assert an exact
  # scheduler set (nixpkgs does — correct for a pinned release, but it would
  # break this package on every upstream scheduler change).
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

  # Static list of the schedulers this package builds, for a consumer that
  # needs the names at evaluation, where $out cannot be read.
  # Refreshed against upstream as needed; the build no longer enforces it.
  passthru.schedulers = [
    "scx_bpfland"
    "scx_chaos"
    "scx_cosmos"
    "scx_flash"
    "scx_lavd"
    "scx_layered"
    "scx_mitosis"
    "scx_p2dq"
    "scx_rlfifo"
    "scx_rustland"
    "scx_rusty"
    "scx_tickless"
  ];

  meta = {
    description = "Sched-ext Rust userspace schedulers (git main)";
    longDescription = ''
      Bleeding-edge sched_ext userspace schedulers built from the tip of
      sched-ext/scx main: scx_rusty, scx_lavd, scx_layered, scx_bpfland,
      scx_flash, scx_rustland and others.

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
})
