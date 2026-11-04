# OpenVDR development state

## Intent and baseline

Build a coherent Rust-first desktop/headset application. Desktop streaming
must not depend on SteamVR; Windows/Linux PCVR is a separate mode. Prioritize
usable streaming and easy setup, preserve advanced controls and owner choice.

Baseline: ALVR v20.14.1 at a9f6542fa507a841f40ab4f3fcb531427cd02550.
OpenVR: 4c85abcb7f7f1f02adaf3812018c99fc593bc341.
Upstream history, original licenses and source layout are preserved.

GitLab: https://gitlab.curtpme.com/cpjet64/OpenVDR (project 315).
GitHub: https://github.com/cpjet64/OpenVDR (downstream mirror destination).
Issues may be filed on either; cross-link GitHub reports to canonical GitLab
implementation work. GitHub Actions are disabled at repository level.

## Active milestone

Reproducible developer preview: native Windows streamer build/package, Android
APK build/package inspection, independent behavior checks. Neither a branded
launcher nor successful compilation proves desktop/headset streaming.

Curt confirmed no Quest headset is available locally. All headset installation,
video/audio/input, reconnect and latency acceptance remains pending device tests.
Linux/macOS desktop and Windows/Linux PCVR support are not yet qualified.

## Architecture review

Architect chat: 6aeab6d5-d168-83e9-a2ae-d380ff0938c2. Curt authorized direct
updates, questions and review packets after every push. Startup review confirmed
ALVR v20.14.1, minimal source changes, scoped repeatable dependency preparation,
and the developer-preview milestone given unavailable hardware.

Do not distribute FFmpeg configurations with `--enable-nonfree`. They are not
another open-source licensing choice. The initial Windows baseline excludes
the `gpl` feature; actual component notices still govern redistribution.

## Behavior contracts and assumptions

- Manual update mode means no background update request. Notify/idle automatic
  update are opt-in. Updates must not interrupt streaming or gate compatible use.
- Protocol negotiation, application version, settings schema and Android
  versionCode are separate contracts. No desktop protocol change is approved yet.
- Root status alone must not prevent use. LAN pairing and direct addressing must
  work offline after platform setup. Remote input requires explicit ownership.
- Simple/advanced controls share typed settings; explicit values persist.
- No application accounts, relay service, new virtual audio driver, or pure-Rust
  rewrite is assumed necessary for the first useful version.
- Pre-1.0 incompatible public-contract changes require documented migration and
  a minor version change; a new release alone must not invalidate compatible peers.

## Validation and delivery boundaries

Initial CI runs the inherited portable core/session checks on Debian and macOS.
It is baseline evidence, not a full Linux/macOS host build or upstream workflow
parity. Full native/Android packaging and hardware qualification remain separate
required preview/release gates. Release jobs and signing are not activated yet.

Windows native build runs locally first. One expensive build at a time, four
compiler jobs initially. Keep at least 40 GiB free on the project volume.
Use `.local` for task state and `.worktrees` for isolated worker branches.

GitLab push mirror 2 uses a GitLab-managed SSH identity and GitHub deploy key
168679106, with GitHub host keys pinned from its official API. Divergent refs
are preserved. Mirror verification awaits the first downstream push. Release
assets require separate publication; Git mirroring alone does not publish them.

Known setup gaps: Android SDK/NDK tooling has not been established. No alpha
release, signing, deployment, or identical release asset publication has occurred.
