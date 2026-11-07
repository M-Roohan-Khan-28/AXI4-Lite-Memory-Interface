# AXI4-Lite Master and Slave Memory Interface

A standalone, CPU-independent 32-bit AXI4-Lite path connecting a request interface, master, slave, and synchronous SRAM. It includes byte-write strobes, independently handshaken channels, a small integration top, and seven self-checking directed testbenches.

The interface, master, slave, and SRAM were extracted byte for byte from [RV32I-AXI4-Lite-SoC](https://github.com/M-Roohan-Khan-28/RV32I-AXI4-Lite-SoC) at commit `ceacccb687b39af045431f2ce4d1205276780b6a`. The repository adds independent harnesses, launchers, and recorded evidence. Its supported behaviour and verification limits are documented below.

```mermaid
flowchart LR
    Request[CPU-independent request port] --> Master[AXI4-Lite master]
    Master -- AW / W / B / AR / R --> Slave[AXI4-Lite slave]
    Slave --> SRAM[Synchronous 32-bit SRAM]
```

## Quick start

From this repository root on Windows, with `vlib`, `vlog`, and `vsim` from ModelSim Intel FPGA Starter Edition 2020.1 on PATH:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1 -OutputDir run-output
```

The launcher refuses to overwrite an existing output directory. Supply a new `-OutputDir` for each rerun. It compiles the minimal ordered files in `sim/rtl.f` and `sim/testbenches.f`, runs seven self-checking tops, checks `$finish` and pass markers, and exits nonzero on a compile, elaboration, simulation, or log failure. Raw logs for the validated local run are in `reports/validation-2026-11-05/`. [Results](docs/RESULTS.md) give the exact tested version, command, counts, and limitations.

For WSL/Linux, `bash sim/run.sh /path/to/new-output` is the shell entry point when a compatible ModelSim/Questa installation provides `vlib`, `vlog`, and `vsim` on PATH. The launcher passed `bash -n` in WSL, but the WSL environment here lacks those simulator executables, so its full regression has not run. The PowerShell path above is the validated path.

## Design scope

- One shared clock, synchronous active-low reset, 32-bit data/address, and one outstanding master request.
- Master emits AW/W together but independently holds each until accepted. The slave can accept AW and W in either order and keeps B/R responses stable during backpressure.
- Byte-lane writes support all 16 WSTRB values. The default SRAM is 1,024 words at `0x10000000`; misaligned/out-of-range requests return SLVERR. SRAM contents are uninitialized at power-up and retained across reset.
- The new `axi4_lite_memory_top` connects the copied master, slave, and SRAM behind a simple request/completion interface. Direct slave and controlled-responder tests exercise behavior that the integrated master traffic alone would miss.

See [specification](docs/SPECIFICATION.md), [test plan](docs/TEST_PLAN.md), [results](docs/RESULTS.md), and [provenance](docs/PROVENANCE.md). The original SoC's three AXI tests, SRAM test, helper modules, and historical logs are preserved under `tb/legacy/` and `historical_logs/`. No processor or SoC file list is copied into the standalone build. `LICENSE_STATUS.md` describes the source licensing state.

The required project runner now executes the [response-order checker](docs/RESPONSE_ORDER_QUALIFICATION.md)
after its seven functional tests. It requires one legal case and all eight
expected-negative detections; these qualification counts are reported
separately from the seven functional tests. A missing tool, timeout, missing
case, or unexpected diagnostic fails the project wrapper.
The checker observes pre-edge AW/W/AR acceptance and rejects early B/R even under
backpressure. Its old-checker controls, corrected eight-case qualification,
fresh seven-test regression, and measured waveform have separate evidence.

## Limits

This project does not implement bursts, DMA, a CPU, an interconnect, UVM, or new arbitration features. No licensed randomization, covergroup, or concurrent assertion execution is required by the portable regression. The tested results do not establish full AXI4-Lite compliance, coverage closure, synthesis, timing closure, or hardware operation. The source SRAM and master have no hardware timeout; the testbench timeout is an environment guard.
