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
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = (Get-Command vsim -ErrorAction Stop).Source
        $psi.Arguments = "-c -onfinish exit $top -do `"onerror {quit -code 1}; run -all; quit -code 0`""
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $proc = [Diagnostics.Process]::Start($psi)
        try {
            $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
            $stderrTask = $proc.StandardError.ReadToEndAsync()
            $finished = $proc.WaitForExit(120000)
            if (-not $finished) { $proc.Kill(); $proc.WaitForExit() }
            $stdout = $stdoutTask.GetAwaiter().GetResult()
            $stderr = $stderrTask.GetAwaiter().GetResult()
            [IO.File]::WriteAllText((Join-Path $testOut 'simulation.log'), $stdout + $stderr)
            if (-not $finished) { throw "Simulation timed out after 120 seconds: $top" }
            $simExit = $proc.ExitCode
        } finally { $proc.Dispose() }
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
$python = Get-Command py.exe -ErrorAction SilentlyContinue
if (-not $python) { throw 'Python 3 launcher missing for required checker qualification' }
$qualificationOut = Join-Path $out 'checker-response-order'
& $python.Source -3 (Join-Path $PSScriptRoot 'run_checker_response_order.py') --repo-root $repo --output-dir $qualificationOut
$qualificationExit = $LASTEXITCODE
$qualificationPath = Join-Path $qualificationOut 'RESULTS.json'
if ($qualificationExit -ne 0 -or -not (Test-Path -LiteralPath $qualificationPath)) {
    throw "Checker qualification failed or results missing (exit $qualificationExit)"
}
$qualification = Get-Content -LiteralPath $qualificationPath -Raw | ConvertFrom-Json
$cases = @($qualification.cases)
$positive = @($cases | Where-Object { $_.case -eq 0 -and $_.result -eq 'LEGAL_TRAFFIC_ACCEPTED' }).Count
$negative = @($cases | Where-Object { $_.case -ge 1 -and $_.case -le 8 -and $_.result -eq 'EXPECTED_VIOLATION_DETECTED' }).Count
if ($qualification.overall -ne 'QUALIFICATION_PASS' -or $qualification.baseline_probe -or
    $cases.Count -ne 9 -or (@($cases.case | Select-Object -Unique)).Count -ne 9 -or
    $positive -ne 1 -or $negative -ne 8) {
    throw 'Checker qualification did not report one legal and eight distinct expected-negative results'
}
$result = [ordered]@{
    repository = 'AXI4-Lite-Memory-Interface'
    source_revision = (& git -C $repo rev-parse HEAD).Trim()
    functional_tests = $tests.Count
    checker_positive = $positive
    checker_expected_negative = $negative
    checker_qualification_exit_code = $qualificationExit
    status = 'PASS'
}
$result | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $out 'results.json')
Write-Output "CHECKER_QUALIFICATION_PASS positive=$positive expected_negative=$negative"
Write-Output "REGRESSION_PASS tests=$($tests.Count) output=$out"
