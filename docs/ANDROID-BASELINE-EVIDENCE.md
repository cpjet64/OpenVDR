# Android developer baseline evidence

On 2026-11-04 the [Android build recipe](ANDROID-BUILD.md) completed on Windows
using source commit `78533e646ccde2e62fcdfeb2f3c52eeab1ea3029`, which includes
main commit `75093f08`. This is a developer build, not a qualified release.
The debug-signed APK was 189,256,618 bytes with SHA-256
`6554aff099644b43a2a59d46202844f9c2db81c26dcba5b6a757cd92056fe2bb`.

`apksigner verify --verbose` passed APK signature schemes v2 and v3. Android
build-tools `aapt dump badging` identified package `alvr.client.stable`, version
`20.14.1`, minimum API 26 and target API 32. Archive integrity passed. Its only
native libraries were the arm64 ALVR client and generic OpenXR loader, and the
embedded loader matched the pinned SHA-256 in the recipe. The SDK license was
accepted with the product owner's explicit authorization. The debug signing key
was generated in the worktree's `.local/android-user` directory.

No installation, headset, runtime, connection, or streaming test was performed.
Quest 1 and vendor-specific loader coverage remain unqualified. The manifest
retains upstream device declarations, which are not device compatibility proof.
