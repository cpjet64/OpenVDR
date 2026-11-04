param([string]$Package = (Join-Path $PSScriptRoot '../.local/windows-baseline'))
$ErrorActionPreference = 'Stop'
$packagePath = (Resolve-Path -LiteralPath $Package).Path
$exe = Join-Path $packagePath 'ALVR Dashboard.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Build the baseline first.' }
# Upstream startup terminates other dashboards. Never let this smoke affect one.
if (Get-Process -Name 'ALVR Dashboard' -ErrorAction SilentlyContinue) {
    throw 'An existing ALVR dashboard is running; preserve it and defer this smoke.'
}
if (Test-Path -LiteralPath (Join-Path $packagePath 'session.json')) {
    throw 'Smoke requires a fresh package with no existing session settings.'
}
$process = Start-Process -FilePath $exe -WorkingDirectory $packagePath -WindowStyle Hidden -PassThru
$owned = @{}
try {
    for ($sample = 0; $sample -lt 30; $sample++) {
        Start-Sleep -Seconds 1
        $process.Refresh()
        if ($process.HasExited) { throw "Dashboard exited early: $($process.ExitCode)" }
        $all = @(Get-CimInstance Win32_Process)
        $parents = @($process.Id) + @($owned.Keys)
        foreach ($child in $all) {
            if ($child.ParentProcessId -in $parents -and $child.CreationDate -ge $process.StartTime) {
                $owned[$child.ProcessId] = $child.CreationDate
            }
        }
        if ($process.MainWindowTitle -eq 'ALVR Dashboard (streamer v20.14.1)' -and $process.Responding) { break }
    }
    if ($process.MainWindowTitle -ne 'ALVR Dashboard (streamer v20.14.1)' -or -not $process.Responding) {
        throw "Dashboard did not initialize within 30 seconds. Window: $($process.MainWindowTitle)"
    }
    # A fresh upstream session remains in memory until settings are changed.
    Write-Host 'Startup smoke passed: expected dashboard window initialized and responds. No headset or visual UI acceptance is implied.'
} finally {
    foreach ($childId in $owned.Keys) {
        $child = Get-Process -Id $childId -ErrorAction SilentlyContinue
        if ($child -and $child.StartTime -ge $process.StartTime) {
            Stop-Process -Id $childId -ErrorAction Stop
            Wait-Process -Id $childId -Timeout 10 -ErrorAction SilentlyContinue
        }
    }
    $process.Refresh()
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -ErrorAction Stop
        $process.WaitForExit(10000) | Out-Null
        if (-not $process.HasExited) { throw 'Task dashboard did not exit.' }
    }
    Write-Host "Task dashboard PID $($process.Id) stopped; tracked descendants: $($owned.Count)."
}
