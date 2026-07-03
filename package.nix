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
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "scx-git";
  # Auto-updated by scripts/update.sh (versionScheme: unstable-date).
  version = "1.1.1-unstable-2026-07-03";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "d624f3322427cd30c29b8c8f507eb005fe546468";
    hash = "sha256-igrmrfimVOEJnFxMr9ghN6lAHwEBSFLLVrB2MQ72PXI=";
  };

  # Regenerated on every bump by the updater (build-extract). The Cargo.lock
  # of git main moves, so this is not stable across revisions.
  cargoHash = "sha256-CTEVdvw6aG/fFas2Fk3x9o4Sp2k3lHO/OLwUM8t9UjE=";

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

  # Helper/dev binaries we don't ship. rm -f (not rm): the set drifts on git
  # main, and a removed helper must not fail the build.
  postInstall = ''
    rm -f $out/bin/scx_arena_selftests $out/bin/vmlinux_docify $out/bin/xtask $out/bin/scx_forge_agent
  '';

  __structuredAttrs = true;

  # git main adds/removes schedulers continuously, so do NOT assert an exact
  # scheduler set (nixpkgs does — correct for a pinned release, but it would
  # break this package on every upstream scheduler change). Sanity-check only
  # that the workspace actually produced a reasonable number of schedulers.
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
    runHook postInstallCheck
  '';

  # Static list for the services.scx `scheduler` enum (a NixOS module reads
  # cfg.package.schedulers at eval time, so this can't be derived from $out).
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
