# OpenVDR

OpenVDR is developing an open-source desktop and PCVR streaming application,
with simple setup, advanced controls, offline local use and owner-controlled
updates. Rust is the primary language. The starting foundation is
[ALVR v20.14.1](https://github.com/alvr-org/ALVR/tree/a9f6542fa507a841f40ab4f3fcb531427cd02550).

**Development baseline only. No OpenVDR alpha is released and desktop-to-headset
streaming has not been implemented or qualified.** Inherited ALVR UI names and
version numbers are retained while the baseline is reproduced. Upstream support
claims are not OpenVDR support claims.

The native Windows streamer builds from the pinned source. Quest hardware is
unavailable locally; real video, audio, input, pairing, reconnect and latency
acceptance remain pending. Linux/macOS desktop support is planned, not verified.

- [Build the Windows baseline](docs/BUILDING.md).
- [Build the Android developer APK](docs/ANDROID-BUILD.md).
- [Dependency inventory and source SBOM scope](docs/DEPENDENCIES.md).
- [Desktop integration assessment](docs/DESKTOP-FEASIBILITY.md).
- [Current milestone, contracts and blockers](docs/OPENVDR-STATE.md).
- [Changelog](CHANGELOG.md).

[GitLab](https://gitlab.curtpme.com/cpjet64/OpenVDR) is authoritative for source
and CI. [GitHub](https://github.com/cpjet64/OpenVDR) is the downstream mirror.
Issues are welcome on either host; implementation tracking is canonical on
GitLab. GitHub Actions are disabled. Source mirroring does not publish release
assets; release publication and updater manifests are separate future gates.

Original licenses and provenance are retained. Our independent new code is MIT;
the distribution license and required notices depend on the actual included
components and features. See [LICENSE](LICENSE) and the component inventory.
No binary produced with FFmpeg `--enable-nonfree` may be distributed.

The original upstream [README](docs/upstream/ALVR-README.md),
[changelog](docs/upstream/ALVR-CHANGELOG.md), and GitHub workflow files remain
archived for provenance. Their instructions describe upstream and may perform
global installations; use the OpenVDR build recipe instead.
