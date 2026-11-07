# AXI4-Lite response-order checker qualification

This bounded checker observes accepted AW, W, and AR transfers. It rejects
`BVALID` until both write requests were accepted and rejects `RVALID` until an
AR was accepted, including cycles with `BREADY` or `RREADY` low. The checker
uses pre-edge state. It accepts legal AW-first, W-first, and same-edge AW/W
ordering. This qualifies the passive checker; it is not full AXI4-Lite
compliance or a DUT coverage result.

The reviewed source was `a7b9540f225282e1ffbddf84531e6e5a34e73a86`.
The corrected checker and directed test were first committed at
`aa5e494f65f00c182f91cb7ae4cdc4658ce62076`. The supplied old checker
was reconstructed from that reviewed baseline, byte-checked by the runner,
and used only in a disposable negative control.

| Run | Observed result | Evidence |
| --- | --- | --- |
| Old checker | Legal positive accepted; all 8 isolated early-response cases escaped the old checker and triggered the test's missing-detection fatal | [raw logs and JSON](../reports/technical-completion-2026-11-07/baseline-negative-control/) |
| Corrected checker at `aa5e494` | Legal positive accepted; all 8 isolated violations produced the expected checker fatal | [raw logs and JSON](../reports/technical-completion-2026-11-07/corrected-qualification/) |
| Existing DUT regression at `aa5e494` | 7/7 tests passed, wrapper exit 0 | [raw logs](../reports/technical-completion-2026-11-07/functional-regression/) |

All runs used ModelSim Intel FPGA Starter Edition `vsim 2020.1 Simulator
2020.02 Feb 28 2020`, directed stimulus without an RNG seed. Each case has a
60-second subprocess timeout. The original qualification wrapper assumed
ModelSim returned nonzero on `$fatal`; this installation instead returned
process exit 0 while logging the fatal and `Errors: 1`. The committed runner
requires exactly the expected fatal diagnostic and rejects missing or unrelated
diagnostics. Actual simulator exits are in `RESULTS.json`.

Reproduce from a clean checkout using a new output directory:

```powershell
$env:MODELSIM_BIN = 'C:\intelFPGA\20.1\modelsim_ase\win32aloem'
py -3 scripts/run_checker_response_order.py --output-dir C:\short\axil-checker-unique
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1 -OutputDir C:\short\axil-seven-unique
```

The [measured waveform](../reports/technical-completion-2026-11-07/measured-waveform/legal-selected.svg)
comes from the committed checker qualification top, not a hand-drawn timing
diagram. Its [raw selected-signal VCD](../reports/technical-completion-2026-11-07/measured-waveform/legal-selected.vcd),
[capture log](../reports/technical-completion-2026-11-07/measured-waveform/legal-selected.log),
and [renderer metadata](../reports/technical-completion-2026-11-07/measured-waveform/legal-selected.json)
record the actual 1 ps VCD timebase and source hash. The selected signals are
clock, reset, and the five AXI4-Lite VALID/READY pairs. `tools/vcd_to_svg.py`
renders VCD samples but does not assess protocol correctness.

The original RTL, legacy testbenches, provenance, and historical reports are
unchanged. The original advanced ALU/APB environments remain separately
licence-blocked and NOT RUN; no synthesis, timing, FPGA, or hardware claim is
implied by these checker tests.
