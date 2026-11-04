param(
    [switch]$PreflightOnly,
    [string]$LibClangPath = $env:LIBCLANG_PATH
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$openvr = Join-Path $root 'openvr'
$expectedOpenvr = '4c85abcb7f7f1f02adaf3812018c99fc593bc341'
$output = Join-Path $root '.local/windows-baseline'
$target = Join-Path $root '.local/cargo-windows-baseline'

function Require-File([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing required file: $Path" }
}

function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed with exit code $LASTEXITCODE" }
}

function Test-Prerequisites {
    if ($env:OS -ne 'Windows_NT' -or $env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
        throw 'This recipe requires native x64 Windows.'
    }
    foreach ($name in @('git', 'rustup')) {
        if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Missing $name on PATH." }
    }
    $version = & rustup run stable rustc --version
    if ($LASTEXITCODE -ne 0 -or $version -notmatch '^rustc 1\.99\.0\b') {
        throw 'The installed stable toolchain must be Rust 1.99.0 for this recipe.'
    }
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    Require-File $vswhere
    $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($LASTEXITCODE -ne 0 -or -not $vs) { throw 'MSVC x64 C++ build tools were not found.' }
    $sdk = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits/10/Include'
    $sdkVersions = @(Get-ChildItem -LiteralPath $sdk -Directory -ErrorAction SilentlyContinue | Where-Object {
        (Test-Path -LiteralPath (Join-Path $_.FullName 'um/Windows.h')) -and
        (Test-Path -LiteralPath (Join-Path $_.FullName 'ucrt/stdio.h'))
    })
    if ($sdkVersions.Count -eq 0) { throw 'Windows SDK headers were not found.' }
    if (-not $LibClangPath) { throw 'Set LIBCLANG_PATH or pass -LibClangPath to a directory containing libclang.dll.' }
    Require-File (Join-Path $LibClangPath 'libclang.dll')
    $head = & git -C $openvr rev-parse HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or $head -ne $expectedOpenvr) { throw "Initialize OpenVR at $expectedOpenvr before building." }
    $dirty = & git -C $openvr status --porcelain --untracked-files=normal
    if ($LASTEXITCODE -ne 0 -or $dirty) { throw 'OpenVR must be clean, including untracked files.' }
    foreach ($file in @('headers/openvr.h', 'lib/win64/openvr_api.lib', 'bin/win64/openvr_api.dll', 'LICENSE')) {
        Require-File (Join-Path $openvr $file)
    }
    Write-Host "Prerequisites found: $version; MSVC at $vs; Windows SDK $($sdkVersions[-1].Name); OpenVR $head"
}

function Build-Baseline {
    if (Test-Path -LiteralPath $output) { throw "Output already exists: $output. Preserve or move it before building." }
    $oldTarget = $env:CARGO_TARGET_DIR
    $oldClang = $env:LIBCLANG_PATH
    try {
        $env:CARGO_TARGET_DIR = $target
        $env:LIBCLANG_PATH = $LibClangPath
        Push-Location $root
        try {
            Invoke-Checked rustup @('run', 'stable', 'cargo', 'build', '--locked', '--release', '-j', '4', '-p', 'alvr_server_openvr', '-p', 'alvr_dashboard')
        } finally { Pop-Location }
    } finally {
        $env:CARGO_TARGET_DIR = $oldTarget
        $env:LIBCLANG_PATH = $oldClang
    }
    $release = Join-Path $target 'release'
    $driver = Join-Path $output 'bin/win64'
    foreach ($file in @('alvr_server_openvr.dll', 'alvr_server_openvr.pdb', 'alvr_dashboard.exe')) {
        Require-File (Join-Path $release $file)
    }
    New-Item -ItemType Directory -Path $driver -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $release 'alvr_server_openvr.dll') -Destination (Join-Path $driver 'driver_alvr_server.dll')
    Copy-Item -LiteralPath (Join-Path $release 'alvr_server_openvr.pdb') -Destination $driver
    Copy-Item -LiteralPath (Join-Path $release 'alvr_dashboard.exe') -Destination (Join-Path $output 'ALVR Dashboard.exe')
    Copy-Item -LiteralPath (Join-Path $openvr 'bin/win64/openvr_api.dll') -Destination $driver
    Copy-Item -LiteralPath (Join-Path $root 'alvr/server_openvr/cpp/bin/windows/vcruntime140_1.dll') -Destination $driver
    Copy-Item -LiteralPath (Join-Path $root 'alvr/xtask/resources/driver.vrdrivermanifest') -Destination $output
    Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $output 'LICENSE-ALVR')
    Copy-Item -LiteralPath (Join-Path $openvr 'LICENSE') -Destination (Join-Path $output 'LICENSE-OpenVR')
    Write-Host "Baseline package created at $output"
}

Test-Prerequisites
if (-not $PreflightOnly) { Build-Baseline }
