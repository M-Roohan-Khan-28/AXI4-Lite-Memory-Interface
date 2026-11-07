# AXI4-Lite checker qualification in the required project run

Clean detached GitHub source `8d8887abf1ffb9fcd3b153623419d96343545c47`.
ModelSim Intel FPGA Starter Edition
`vsim 2020.1 Simulator 2020.02 Feb 28 2020`.
Directed tests; no pseudorandom seed.

The fresh project wrapper returned **0**: seven functional test tops passed,
and the checker accepted one legal scenario and detected all eight distinct
expected-negative response-order violations. Functional and qualification
counts are separate in `clean-clone/results.json`. The checker case logs,
`RESULTS.json`, source and version hashes, all functional compile/simulation
logs, and wrapper console are under `clean-clone/`.

The first clean-clone attempt at source `91083b72c578977ddc62e9bf969fc7b0e87df465`
failed with wrapper exit **1** because the new bounded `vsim` subprocess
started outside its compiled `work` library. `failed-launcher/` retains that
console and simulator error. Commit `8d8887a...` set the subprocess working
directory; the subsequent fresh clone and new-output run passed. This
failed attempt is not counted as a passing test.

Reproduce with unused paths:

```powershell
git -c core.autocrlf=false clone --branch technical/response-order-qualification https://github.com/M-Roohan-Khan-28/AXI4-Lite-Memory-Interface.git C:\short\axil-new
git -C C:\short\axil-new config core.autocrlf false
git -C C:\short\axil-new checkout --detach 8d8887abf1ffb9fcd3b153623419d96343545c47
$env:PATH = 'C:\intelFPGA\20.1\modelsim_ase\win32aloem;' + $env:PATH
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\short\axil-new\scripts\run_regression.ps1 -OutputDir C:\short\axil-new-output
if ($LASTEXITCODE -ne 0) { throw 'AXI4-Lite required suite failed or blocked' }
```
