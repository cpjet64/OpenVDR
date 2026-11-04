# OpenVDR

OpenVDR is a Rust-first open-source desktop and PCVR streaming product. Curt is
the product owner. Preserve the ALVR baseline and notices; do not claim a usable
OpenVDR release from a launcher, compilation, or mocked stream.

## Current baseline and scope

- Upstream: ALVR v20.14.1, a9f6542fa507a841f40ab4f3fcb531427cd02550.
- Initial gate: reproduce the Windows baseline and resolve the dependency
  inventory before altering the media path. Quest hardware is unavailable;
  headset and end-to-end streaming acceptance remain explicitly pending.
- Desktop mode must ultimately work without SteamVR. Windows/Linux PCVR and
  Windows/Linux/macOS desktop support are distinct qualification tracks.
- Manual updates by default; no account or Internet requirement for local
  streaming; preserve explicit settings and support direct addressing.
- Do not run upstream dependency preparation without inspecting its effects.
  No WSL, Docker, global installs, or persistent environment changes.

## Ownership and worktrees

- Coordinator owns main, Cargo manifests/lockfile, CI, contracts, integration,
  and review packets. Workers use agent/<task> branches in .worktrees/<task>.
- Delegate bounded independent tasks to GPT-6.1 Terra, low or medium reasoning.
  Each worker must receive exact ownership, checks, and handoff requirements.
- Keep task state under .local; isolate output or serialize expensive builds.
  Start with at most one native build, four compiler jobs.
- Never discard pre-existing changes. Commit explicit owned paths only.
- Remove clean integrated task worktrees after push and reachability proof.

## Delivery

- GitLab is authoritative; GitHub is a one-way source/release mirror. No
  executable GitHub Actions workflows may be pushed downstream.
- Local Windows validation precedes push. Debian/macOS non-E2E gates are
  mandatory; full platform builds and hardware qualification are separate.
- Use verified unprotected runner boundaries for validation. No interactive
  GPU/headset tests on headless runners. CurtPME's condensed runner topology
  is accepted as scheduling separation, not physical security isolation.
- No alpha tag until usable alpha acceptance. Keep upstream versions intact
  during baseline reproduction; OpenVDR releases start at 0.1.0-alpha.1.
- Preserve component licenses. Newly authored independent code is MIT;
  distribution licensing follows actual included components and build flags.
- Send every push's exact-SHA review packet to the linked architect session:
  6aeab6d5-d168-83e9-a2ae-d380ff0938c2. Never claim review before receiving it.
- New authored files/functions obey the machine-global 500/75 limits.
