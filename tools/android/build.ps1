param([string]$JavaHome = 'C:\Program Files\Microsoft\jdk-21.0.11.10-hotspot')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if ((Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($root).Substring(0,1))).Free -lt 40GB) { throw 'Less than 40 GiB free.' }
$env:RUSTUP_HOME = Join-Path $root '.local/rustup'
$env:CARGO_HOME = Join-Path $root '.local/cargo'
$env:ANDROID_HOME = Join-Path $root '.local/sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_NDK_ROOT = Join-Path $root '.local/sdk/ndk/26.1.10909125'
$env:ANDROID_USER_HOME = Join-Path $root '.local/android-user'
Remove-Item Env:ANDROID_SDK_HOME -ErrorAction SilentlyContinue
$env:JAVA_HOME = $JavaHome
$env:CARGO_BUILD_JOBS = '4'
$toolchain = Join-Path $env:RUSTUP_HOME 'toolchains/1.99.0-x86_64-pc-windows-msvc/bin'
$env:RUSTC = Join-Path $toolchain 'rustc.exe'
$env:PATH = "$(Join-Path $root '.local/cargo-apk-install/bin');$toolchain;$(Join-Path $JavaHome 'bin');$env:PATH"
$target = Join-Path $root '.local/android-target'
$loaderDir = Join-Path $root 'deps/android_openxr/arm64-v8a'
$libraries = @(Get-ChildItem -LiteralPath (Split-Path $loaderDir) -File -Recurse)
if ($libraries.Count -ne 1 -or $libraries[0].Name -ne 'libopenxr_loader.so' -or
    (Get-FileHash $libraries[0].FullName -Algorithm SHA256).Hash -ne 'B5F805512706A3E01AE523D7216F676854D3F1E1A26FF55268FCB451E6FF0A80') {
    throw 'Expected only the pinned generic arm64 OpenXR loader.'
}
if ((git -C (Join-Path $root 'openvr') rev-parse HEAD) -ne '4c85abcb7f7f1f02adaf3812018c99fc593bc341') { throw 'OpenVR checkout does not match the recorded commit.' }
$lock = Join-Path $root 'Cargo.lock'
$before = (Get-FileHash $lock -Algorithm SHA256).Hash
Push-Location (Join-Path $root 'alvr/client_openxr')
try {
    cargo apk -- build --locked --target-dir $target
    if ($LASTEXITCODE -ne 0) { throw "Locked Android compilation failed: $LASTEXITCODE" }
    cargo apk build --target-dir $target
    if ($LASTEXITCODE -ne 0) { throw "APK packaging failed: $LASTEXITCODE" }
    if ((Get-FileHash $lock -Algorithm SHA256).Hash -ne $before) { throw 'Cargo.lock changed during packaging.' }
} finally { Pop-Location }
