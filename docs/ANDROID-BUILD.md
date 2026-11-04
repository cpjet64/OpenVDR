# Android developer baseline

This produces an ALVR 20.14.1 arm64 developer APK for packaging inspection.
It is not a release, hardware qualification, or proof of streaming. Quest
hardware was unavailable. Only the generic Khronos OpenXR loader is included;
Quest 1 and vendor-specific loader coverage are outside this baseline.

Use Windows with Git, PowerShell, Rustup, Visual Studio C++ build tools, and a
JDK 21 installation. Initialize the OpenVR submodule at the recorded commit
`4c85abcb7f7f1f02adaf3812018c99fc593bc341`. Allow at least 40 GiB free and
network access. Read the [Android SDK license](https://developer.android.com/studio/terms)
before explicitly accepting it. The bootstrap downloads Android command-line
tools, API 32, build tools 32.0.0, NDK 26.1.10909125, Rust 1.99.0 with its
arm64 Android target, the pinned cargo-apk fork and crates, and the loader.
Everything it installs is inside this worktree. It does not use upstream
`prepare-deps`, install global tools, start adb or an emulator, or change a
persistent environment variable. Review the scripts before running them.

```powershell
./tools/android/bootstrap.ps1 -AcceptAndroidSdkLicense
./tools/android/build.ps1
```

Pass `-JavaHome 'C:\path\to\jdk-21'` to each script if needed. The build first
compiles with the repository lockfile enforced, then packages with cargo-apk;
that fork's package command does not expose `--locked`, so the script also
checks that `Cargo.lock` did not change. Both invocations use four compiler
jobs and output under `.local/android-target`. The APK uses a developer-only
debug key generated under `.local/android-user`; never use it for production.
Keep this directory private and do not publish the key. The bootstrap refuses
to proceed without an explicit SDK license acceptance switch.

Inputs pinned for this recipe:

- Google command-line tools 12.0 Windows archive `commandlinetools-win-11076708_latest.zip`, SHA-256 `4d6931209eebb1bfb7c7e8b240a6a3cb3ab24479ea294f3539429574b1eec862`. Google's repository metadata records SHA-1 `3d2917302740f476999a091bc5558837c7a863c5`.
- Upstream's `zarik5/cargo-apk` URL redirects to `zmerp/cargo-apk`; commit `0fd3126dad5aa1c5f0f26cdae3410f2e5af62c60` is pinned rather than the floating upstream command. Its Android XR metadata support is needed by this manifest. It is MIT OR Apache-2.0; its locked crate graph is in `tools/android/cargo-apk.lock`.
- [Khronos OpenXR loader 1.0.34](https://github.com/KhronosGroup/OpenXR-SDK-Source/releases/tag/release-1.0.34) AAR SHA-256 `c8b50603ad3b81756c6bd203ab9c9d19341326e14f6cbae87ee894137ee5e256`. The extracted arm64 library SHA-256 is `b5f805512706a3e01ae523d7216f676854d3f1e1a26ff55268fcb451e6ff0a80`; its Apache-2.0 license is extracted to `.local/openxr-license.txt`.

SDK manager resolves the exact requested package revisions through Google's
repository metadata. Its accepted license records are local to the SDK.
Existing contents under `.local` and `deps/android_openxr` should be inspected
before rerunning; do not mix vendor loaders into this generic-only baseline.
The package's manifest retains upstream device declarations, which are not
evidence that every declared device works with this loader.
