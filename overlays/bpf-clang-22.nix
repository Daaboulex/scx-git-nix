{
  meta = {
    reason = "scx main refuses to build its cid-form schedulers (scx_eevdf, scx_nitosis, scx_mavd) with a clang older than 22, which mishandles their arena memory, and nixpkgs' default llvmPackages clang is 21; BPF_CLANG takes llvmPackages_22's clang until the un-fixed scx-git builds";
    added = "2026-09-29";
    upstream = "https://github.com/sched-ext/scx/blob/a730d683cf32a087304c78df04078b5204359abc/rust/scx_cargo/src/bpf_builder.rs#L447-L476";
  };
  dropWhenBuilds = pkgs: pkgs.scx-git;
  overlay = final: prev: {
    scx-git = prev.scx-git.override { llvmPackages = final.llvmPackages_22; };
  };
}
