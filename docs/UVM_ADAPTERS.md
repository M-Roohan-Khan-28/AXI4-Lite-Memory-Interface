# Separate deterministic UVM/SVA adapters

The reusable implementation lives in
[AMBA-Protocol-Verification](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/3da848965b00f97d7488e4b98e362cf21f67644d/docs/DETERMINISTIC_AXIL_UVM.md)
at source revision `3da848965b00f97d7488e4b98e362cf21f67644d`.
It pins this repository to `faf43379b24a524999eb2c8ad7e100cde35054c3`.
These documentation additions change no RTL, existing tests/runners, source
locks, historical reports, licences or attribution.

Three targets compile the existing RTL without modification:

1. A UVM initiator drives the slave and SRAM directly.
2. A UVM responder and CPU-request driver test the master.
3. A CPU-request driver tests the existing `axi4_lite_memory_top` integration.

The bounded configuration uses 16 SRAM words at `0x10000000`, a shared clock
and 32-bit data. A passive public-pin monitor feeds an independent byte memory
and request/response scoreboard. It checks independent AW/W acceptance,
address/data forwarding, strobe effects, invalid-address responses, memory
retention across synchronous reset, and exactly-once CPU completion. The model
never reads internal DUT memory or control state. The active responder uses a
separate word model.

Concurrent assertions check stalled VALID/payload stability and B/R eligibility
even when READY is low. Dependency state comes from prior edges. Thirteen
individually identified expected-negative controls and one legal control qualify
the assertions. Deterministic sequences exercise all 16 strobes, AW-first,
W-first and simultaneous acceptance where controllable, independent READY
stalls, slave B/R backpressure, address boundaries and pending-transaction reset.

## Reproduce from the locked AMBA source

The [published fresh-clone evidence](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/49d41c5859fd8a5111ee3ba19735d32fe4a6134e/reports/axil-uvm-2026-11-08/SUMMARY.md)
records **17/17 required substeps PASS, wrapper exit 0** at the locked source
above. Slave/master/integration completed **274/240/208 transactions** with
**1,577/1,207/1,044 independent comparisons**, respectively. Thirteen negative
assertion controls each produced exactly one expected detection; the legal
control produced none. Five deliberate data/address/progress fault simulations
were rejected for the intended reasons, with all three fault wrappers exiting
**1**. These counts are separate from functional coverage, which is NOT RUN.

Raw logs, JSON, source hashes, seed `0x28A6BEEF`, eight measured figures, and
the capture-byte audit are in that report. All 276 archived artifacts matched
Git blobs and fresh newline-enabled/disabled checkouts; all 17 archived VCDs
also matched public raw downloads. Original capture bytes are preserved.

Use unused paths, Python, Git and the already qualified Questa 2025.2/UVM 1.2
installation. Run sessions serially on the single-session Starter licence:

```powershell
git clone --config core.longpaths=true --config core.autocrlf=false https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification.git C:/short/axil-uvm-adapter-source-new
git -C C:/short/axil-uvm-adapter-source-new checkout --detach 3da848965b00f97d7488e4b98e362cf21f67644d
python C:/short/axil-uvm-adapter-source-new/scripts/run_axil_uvm.py --output C:/short/axil-uvm-adapter-results-new
if ($LASTEXITCODE -ne 0) { throw 'Required AXI4-Lite UVM/SVA substep failed or was blocked' }
```

The single runner command creates fresh detached DUT source clones and executes
17 required substeps serially. Tool/library defaults and override flags are in
the AMBA guide. It emits actual version, commands, SHA locks/hashes, seed,
per-target counts, assertion detections, raw logs, VCDs and `results.json`.
Missing tools/results, simulator errors/fatals and progress/wall timeouts are
failures. Explicit data, address and dropped-response fault controls must return
nonzero and are separate from passing evidence.

## Limits and unexecuted features

The master launches AW/W together and has no externally controlled B/R
backpressure or completion-ready input. Independent channel delays apply to the
standalone master responder; response backpressure applies to the slave target.
Integration retains its original direct wiring. SRAM is initialized by writes,
not reset; pending control is canceled by reset while memory is retained.

Procedural requirement counters are not simulator functional coverage.
Coverage and constrained randomization remain **NOT RUN** because their
required features were licence-blocked in the existing real probes. The original
advanced ALU/APB environments remain **NOT RUN**. This is not a replacement for
the existing portable regression or evidence of full protocol compliance,
overlapping read/write arbitration, all parameter/reset permutations, coverage
closure, synthesis, timing, FPGA or hardware behavior.
