param([string]$OutputDir = 'run-output')

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$out = if ([IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $repo $OutputDir }
if (Test-Path -LiteralPath $out) { throw "Output directory already exists: $out" }
foreach ($tool in @('vlib', 'vlog', 'vsim')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "Required simulator tool missing: $tool" }
}
New-Item -ItemType Directory -Path $out | Out-Null
& vsim -version 2>&1 | Tee-Object -FilePath (Join-Path $out 'simulator-version.txt')
if ($LASTEXITCODE -ne 0) { throw 'Simulator version query failed' }

$sources = @('sim/rtl.f', 'sim/testbenches.f') | ForEach-Object {
    Get-Content (Join-Path $repo $_) | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') } |
        ForEach-Object { Join-Path $repo $_.Trim() }
}
$tests = [ordered]@{
    sram_test = 'PASS SRAM checks=20'
    axi_slave_test = 'PASS AXI slave checks=58'
    axi_master_test = 'PASS AXI master/slave SRAM 26 transactions'
    axi_reset_test = 'PASS AXI partial AW/W reset'
    master_responder_test = 'MASTER_RESPONDER_PASS checks='
    slave_model_test = 'SLAVE_MODEL_PASS checks='
    standalone_top_test = 'STANDALONE_TOP_PASS checks='
}
foreach ($top in $tests.Keys) {
    $testOut = Join-Path $out $top
    New-Item -ItemType Directory -Path $testOut | Out-Null
    Push-Location $testOut
    try {
        & vlib work 2>&1 | Tee-Object -FilePath 'library.log'
        if ($LASTEXITCODE -ne 0) { throw "Library creation failed: $top" }
        & vlog -sv @sources 2>&1 | Tee-Object -FilePath 'compile.log'
        if ($LASTEXITCODE -ne 0) { throw "Compilation failed: $top" }
        & vsim -c -onfinish exit $top -do 'onerror {quit -code 1}; run -all; quit -code 0' 2>&1 |
            Tee-Object -FilePath 'simulation.log'
        $simExit = $LASTEXITCODE
        $log = Get-Content -Raw 'simulation.log'
        if ($simExit -ne 0 -or $log -match '(?im)^\s*#?\s*\*\*\s+(Error|Fatal):' -or
            -not $log.Contains($tests[$top]) -or $log -notmatch '\$finish' -or
            $log -notmatch '(?m)^# Errors: 0, Warnings: 0') {
            throw "Simulation failed: $top (vsim exit $simExit); inspect $testOut"
        }
        Write-Output "PASS $top (vsim exit $simExit)"
    } finally {
        Pop-Location
    }
}
Write-Output "REGRESSION_PASS tests=$($tests.Count) output=$out"
