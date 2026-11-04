param([switch]$AcceptAndroidSdkLicense, [string]$JavaHome = 'C:\Program Files\Microsoft\jdk-21.0.11.10-hotspot')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$local = Join-Path $root '.local'
if (-not $AcceptAndroidSdkLicense) { throw 'Read https://developer.android.com/studio/terms and pass -AcceptAndroidSdkLicense to accept.' }
if ((Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($root).Substring(0,1))).Free -lt 40GB) { throw 'Less than 40 GiB free.' }
New-Item -ItemType Directory -Force $local | Out-Null
$env:JAVA_HOME = $JavaHome
$env:RUSTUP_HOME = Join-Path $local 'rustup'
$env:CARGO_HOME = Join-Path $local 'cargo'
$env:ANDROID_HOME = Join-Path $local 'sdk'
$env:ANDROID_USER_HOME = Join-Path $local 'android-user'
Remove-Item Env:ANDROID_SDK_HOME -ErrorAction SilentlyContinue
$env:CARGO_BUILD_JOBS = '4'
function Get-CheckedFile($url, $path, $sha256) {
    if (-not (Test-Path $path)) { Invoke-WebRequest -Uri $url -OutFile $path }
    if ((Get-FileHash $path -Algorithm SHA256).Hash -ne $sha256) { throw "Hash mismatch: $path" }
}
$cmdZip = Join-Path $local 'cmdtools.zip'
Get-CheckedFile 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip' $cmdZip '4D6931209EEBB1BFB7C7E8B240A6A3CB3AB24479EA294F3539429574B1EEC862'
$cmdDir = Join-Path $local 'sdk/cmdline-tools/current'
if (-not (Test-Path $cmdDir)) {
    $unpack = Join-Path $local 'sdk/cmdline-tools/12.0'
    Expand-Archive -LiteralPath $cmdZip -DestinationPath $unpack
    Move-Item -LiteralPath (Join-Path $unpack 'cmdline-tools') -Destination $cmdDir
}
1..100 | ForEach-Object { 'y' } | & (Join-Path $cmdDir 'bin/sdkmanager.bat') "--sdk_root=$env:ANDROID_HOME" 'platforms;android-32' 'build-tools;32.0.0' 'ndk;26.1.10909125'
if ($LASTEXITCODE -ne 0) { throw "SDK manager failed: $LASTEXITCODE" }
rustup toolchain install 1.99.0 --profile minimal --target aarch64-linux-android --no-self-update
if ($LASTEXITCODE -ne 0) { throw "Rust installation failed: $LASTEXITCODE" }
$bin = Join-Path $env:RUSTUP_HOME 'toolchains/1.99.0-x86_64-pc-windows-msvc/bin'
$env:RUSTC = Join-Path $bin 'rustc.exe'
$fork = Join-Path $local 'cargo-apk-src'
if (-not (Test-Path $fork)) {
    git clone --no-checkout https://github.com/zarik5/cargo-apk.git $fork
    if ($LASTEXITCODE -ne 0) { throw 'cargo-apk clone failed' }
    git -C $fork checkout 0fd3126dad5aa1c5f0f26cdae3410f2e5af62c60
    if ($LASTEXITCODE -ne 0) { throw 'cargo-apk checkout failed' }
}
if ((git -C $fork rev-parse HEAD) -ne '0fd3126dad5aa1c5f0f26cdae3410f2e5af62c60') { throw 'Unexpected cargo-apk revision.' }
if (git -C $fork status --porcelain --untracked-files=normal) { throw 'cargo-apk checkout contains local changes.' }
Copy-Item (Join-Path $PSScriptRoot 'cargo-apk.lock') (Join-Path $fork 'Cargo.lock') -Force
$env:CARGO_TARGET_DIR = Join-Path $local 'cargo-apk-target'
& (Join-Path $bin 'cargo.exe') install --locked --path (Join-Path $fork 'cargo-apk') --root (Join-Path $local 'cargo-apk-install')
if ($LASTEXITCODE -ne 0) { throw "cargo-apk installation failed: $LASTEXITCODE" }
$aar = Join-Path $local 'openxr.aar'
Get-CheckedFile 'https://github.com/KhronosGroup/OpenXR-SDK-Source/releases/download/release-1.0.34/openxr_loader_for_android-1.0.34.aar' $aar 'C8B50603AD3B81756C6BD203AB9C9D19341326E14F6CBAE87EE894137EE5E256'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($aar)
try {
    $destination = Join-Path $root 'deps/android_openxr/arm64-v8a'
    New-Item -ItemType Directory -Force $destination | Out-Null
    $existing = @(Get-ChildItem -LiteralPath (Split-Path $destination) -File -Recurse)
    if ($existing.Count -gt 0 -and ($existing.Count -ne 1 -or $existing[0].Name -ne 'libopenxr_loader.so' -or (Get-FileHash $existing[0].FullName -Algorithm SHA256).Hash -ne 'B5F805512706A3E01AE523D7216F676854D3F1E1A26FF55268FCB451E6FF0A80')) { throw 'Loader directory contains unexpected files.' }
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($zip.GetEntry('prefab/modules/openxr_loader/libs/android.arm64-v8a/libopenxr_loader.so'), (Join-Path $destination 'libopenxr_loader.so'), $true)
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($zip.GetEntry('META-INF/LICENSE'), (Join-Path $local 'openxr-license.txt'), $true)
} finally { $zip.Dispose() }
