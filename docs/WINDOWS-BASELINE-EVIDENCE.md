# Windows baseline evidence — 2026-11-04

This is a developer baseline, not a qualified streaming release.

## Inputs and commands

- ALVR a9f6542fa507a841f40ab4f3fcb531427cd02550; OpenVR
  4c85abcb7f7f1f02adaf3812018c99fc593bc341.
- Rust 1.99.0 (b940084d7); MSVC detected under Visual Studio 18 BuildTools;
  Windows SDK headers 10.0.26100.0; project-local libclang 18.1.1.
- `python tools/bootstrap-libclang.py`: wheel SHA-256 verified before extraction.
- `tools/build-windows.ps1 -LibClangPath "$PWD/deps/libclang-18.1.1"`:
  locked release build and package passed, four compiler jobs, no GPL feature.
- `cargo fmt --all -- --check`: passed.
- `cargo test --locked -p alvr_common -p alvr_packets -p alvr_session -p alvr_filesystem -j 4`:
  four upstream session tests passed. The other three crates contain no tests.
- After changing the notification default, `cargo test --locked -p alvr_session
  -j 4`: four upstream and two new update-policy tests passed.
- `cargo clippy --locked -p alvr_common -p alvr_packets -p alvr_session -p
  alvr_filesystem --all-targets -j 4`: passed with inherited warnings.
- `python -m unittest discover -s tools/dependencies -p 'test_*.py' -v`:
  four inventory checks passed. Source SBOM is not an artifact/native SBOM.
- `tools/smoke-windows.ps1`: expected dashboard title appeared and its window
  responded; task process stopped afterward, zero observed child processes.

## Local artifact identity

Package: `.local/windows-baseline`, retained as runnable acceptance evidence.
This package includes the manual-notification default change; both fresh
disabled and explicit enabled preferences are tested through persistence.

| File | SHA-256 |
| --- | --- |
| ALVR Dashboard.exe | A2CB013E84C01C084B47DD5E2588713F661F6D69CAB921342A0191AE79CC12E7 |
| bin/win64/driver_alvr_server.dll | 611DD2080FB4ECAB1795B1762C2F21DCE55C8547D959053E0C11A4DBB020A570 |

## Failures resolved and limits

The original upstream build failed at bindgen because libclang was missing.
The scoped verified DLL resolved that failure; no global bootstrap ran.
An initial smoke incorrectly required session.json on first launch. Source
inspection confirmed default settings remain in memory until edited; the
corrected startup check verifies the actual window and responsiveness. It does
not claim persistence, visible UI usability, streaming, or hardware acceptance.

Compiler warnings in untouched upstream code remain: elided lifetime style,
float literal fallback, and redundant formatting borrows. No warnings were
suppressed. No actual desktop frame, encoder performance, audio route, headset,
input, pairing, reconnect, signing, or clean-machine installation was validated.
Native third-party notice completeness remains a distribution gate.
