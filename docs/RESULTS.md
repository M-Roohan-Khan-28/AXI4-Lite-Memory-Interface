# Recorded validation — 5 November 2026

The source extraction is from [riscv-axi-soc](https://github.com/rouhan28may-droid/riscv-axi-soc) commit `ceacccb687b39af045431f2ce4d1205276780b6a`. All 19 copied files matched the SHA-256 values in `SOURCE_PROVENANCE.json` before the final run. The hashes of the new RTL, testbenches, scripts and source lists are in the [machine-readable summary](../reports/validation-2026-11-05/summary.json). Original historical logs are preserved in `historical_logs/` and are separate from these fresh results.

Tool: `Model Technology ModelSim - INTEL FPGA STARTER EDITION vsim 2020.1 Simulator 2020.02 Feb 28 2020`. On Windows, `vlib`, `vlog`, and `vsim` were taken from `C:\intelFPGA\20.1\modelsim_ase\win32aloem`. The complete PowerShell regression exited **0** after the clean-source run. Each test compiled with zero errors and zero warnings, reached `$finish`, reported zero simulation errors and zero warnings, and had a simulator exit code of 0.

| Test | Actual pass marker | Configuration |
| --- | --- | --- |
| `sram_test` | 20 checks | Direct SRAM, depth 1,024 |
| `axi_slave_test` | 58 checks | Direct slave/SRAM, default base/depth |
| `axi_master_test` | 26 transactions | Master with five channel delay gates, slave/SRAM, default base/depth |
| `axi_reset_test` | PASS marker; no numeric count printed | Direct slave/SRAM, depth 3 |
| `master_responder_test` | 44 checks; 3 writes, 3 reads | Master versus controlled responder |
| `slave_model_test` | 245 checks; 26 writes, 35 reads | Direct slave/SRAM, base `0x30000000`, depth 7 |
| `standalone_top_test` | 91 checks | Integrated top, base `0x20000000`, depth 5 |

The new tests are deterministic; no seed is used. These check counts are the benches' actual printed counts, not a functional or code-coverage percentage. The [raw compile/simulation logs](../reports/validation-2026-11-05/) and [summary JSON](../reports/validation-2026-11-05/summary.json) contain the individual outcomes and exact command. To reproduce from a clean clone in PowerShell, put the simulator executables on PATH and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1 -OutputDir run-output
```

Choose a new output directory for each run. The launcher rejects an existing directory.

## Failure propagation

In a disposable project copy, SRAM byte-lane writes were temporarily forced to zero. The first SRAM read reported `Fatal: SRAM addr=0 got=00000000 expected=12345678`. ModelSim's process returned 0 despite the fatal, but the wrapper detected the fatal/incomplete run and exited **1**. [Raw failure logs](../reports/fault-injection-2026-11-05/) are retained; the mutated source was never included in this repository. The original SRAM file still matched the source commit's hash. A subsequent fresh clean-source regression passed all seven tests with wrapper exit 0.

## Shell launcher and remaining limits

`wsl bash -n sim/run.sh` exited 0. Running the launcher in this WSL environment exited 1 with `Missing simulator tool: vlib`; Linux/WSL ModelSim execution is therefore **untested**, although the entry point is provided. The Windows PowerShell regression is the validated execution path.

No licensed randomization, covergroups, concurrent assertions, UCDB/code coverage, synthesis, timing closure, FPGA/board testing, or full AXI4-Lite compliance testing was run. The project implements only the bounded behavior described in [SPECIFICATION.md](SPECIFICATION.md). The 256-cycle protocol-checker bound and testbench watchdogs are test assumptions, not AXI protocol timing rules.
