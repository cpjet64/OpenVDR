# Native Windows baseline build

This builds the upstream ALVR Windows streamer baseline without the GPL FFmpeg
feature. It is not a qualified OpenVDR release, a standalone desktop streaming
implementation, or evidence of a working headset stream. Hardware acceptance
remains pending. No upstream dependency preparation script is run.

Use x64 Windows, Git, the installed Rust stable toolchain **1.99.0** with the
`x86_64-pc-windows-msvc` target, Visual Studio C++ x64 build tools, a Windows
SDK, and a compatible x64 `libclang.dll`. Point `LIBCLANG_PATH` at the directory
containing that DLL, or pass `-LibClangPath` to the script. Install these tools
through your established workstation process; this recipe does not install or
change them. Initialize the OpenVR submodule at the commit recorded in the
repository, `4c85abcb7f7f1f02adaf3812018c99fc593bc341`, with a clean checkout.
Cargo may need network access for the dependencies in `Cargo.lock`.

Optionally, Python 3 can fetch the pinned PyPI libclang 18.1.1 Windows wheel,
verify its SHA-256, and extract its DLL and license notices into the ignored
project-local `deps/libclang-18.1.1` directory. It does not use pip or change
global installations. The wheel is about 26 MB; allow additional extraction
space. Review `tools/bootstrap-libclang.py` before running it:

```powershell
python ./tools/bootstrap-libclang.py
./tools/build-windows.ps1 -PreflightOnly -LibClangPath "$PWD/deps/libclang-18.1.1"
./tools/build-windows.ps1 -LibClangPath "$PWD/deps/libclang-18.1.1"
```

From the repository root in PowerShell:

```powershell
./tools/build-windows.ps1 -PreflightOnly -LibClangPath 'C:\path\to\clang\bin'
./tools/build-windows.ps1 -LibClangPath 'C:\path\to\clang\bin'
```

The build uses `cargo build --locked --release` with four jobs and stores Cargo
output under `.local/cargo-windows-baseline`. It creates the upstream Windows
streamer layout in `.local/windows-baseline`, including the dashboard, OpenVR
driver, runtime DLLs, manifest, and ALVR and OpenVR licenses. The script refuses
to overwrite an existing package; preserve or move it before building again.
Preflight checks the presence of dependencies, not their complete compatibility;
the actual build is the definitive compiler and linker check. A failed packaging
operation can leave a partial output directory, which must be examined before a
subsequent attempt. Builds do not run streaming or headset tests.
