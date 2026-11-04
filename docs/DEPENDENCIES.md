# Dependency inventory

This inventory describes ALVR v20.14.1, upstream commit
`a9f6542fa507a841f40ab4f3fcb531427cd02550`, as carried by this checkout.
It is evidence of declared inputs, not a distribution manifest, license
clearance, vulnerability assessment, build, or hardware qualification.

`components-cargo.json` records all 712 Cargo.lock package entries, source
identifiers and registry checksums, plus Cargo's full resolved workspace graph
for x86_64 Windows MSVC, x86_64 Linux GNU, aarch64 and x86_64 macOS, and aarch64 Android.
The graphs use default workspace feature selection, including development and
build dependencies; they are not claims that every package is shipped or that
other feature combinations are covered. Cargo reports enabled features and
dependency kinds/target conditions in `resolve.nodes`. Package license fields
are upstream declarations, not independently audited license conclusions.
Cargo may retain host/build dependencies when filtering a target. Workspace
paths are normalized and local source, readme and license file paths omitted.
`components-native.json` records source-inspected non-Cargo inputs and gaps.
`components-cargo.cdx.json` is a CycloneDX 1.5 source BOM derived from the
union of those Cargo graphs. Its dependency edges are the union across targets;
the inventory preserves per-target graphs. It omits native inputs and is not an
artifact SBOM. Neither document establishes artifact correspondence.

To regenerate with Python 3.11+ and Cargo, from the repository root:

```powershell
python tools/dependencies/inventory.py --offline
```

Remove `--offline` to allow Cargo to fetch the locked sources. The tool runs
`cargo metadata --locked --format-version 1 --filter-platform <triple>` once
per target; it does not compile or execute dependency preparation. Cargo may
download source and write its configured cache. Use a controlled Cargo home if
isolation is required. The command fails rather than emitting a partial graph;
compare the lock SHA-256 and graph with the checked-in file. Cargo version and
metadata schema can affect results. Do not run upstream prepare-deps blindly:
it removes dependency directories, installs global software and sets a
persistent environment variable on Windows.

Windows baseline is the server without the `gpl` feature. Its native build
still needs the OpenVR SDK and Windows compiler/SDK and bindgen/Clang; optional
GPL Windows FFmpeg preparation is not evidence that those binaries are used in
that baseline. Upstream preparation nevertheless downloads a GPL FFmpeg
archive from a mutable `latest` URL and x264, and therefore is unsuitable as
an immutable, non-GPL dependency recipe. Linux always links FFmpeg in the
upstream build; its preparation enables GPL and version3, with nonfree CUDA
options when NVENC is selected. These tracks require separate distribution and
license review, including exact binary provenance, build options and notices.
Distributable builds must not use FFmpeg `--enable-nonfree`; do not create
release packages from outputs built with that flag.

Outstanding: pin and verify native archives and their hashes and licenses,
identify compiler, SDK, driver and system package versions actually used,
inspect vendored native headers and binaries and transitive native dependencies,
resolve vendor loader terms, and generate an artifact-specific SBOM from the
actual build. The Android upstream CI creates an empty loader directory; it is
not proof of packaged runtime loaders. macOS preparation is empty and metadata
resolution is not proof of a supported desktop product. Quest hardware and
streaming acceptance remain pending.
