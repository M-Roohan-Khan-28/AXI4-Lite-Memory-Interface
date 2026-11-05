# Test plan

All tests use deterministic stimulus and a watchdog timeout. The ordered source lists in `sim/` contain only the extracted bus/memory RTL, new top, helpers, and seven testbenches. The PowerShell wrapper uses a fresh library for each top and rejects missing pass markers, missing `$finish`, errors, or nonzero tool exits. The `axi_protocol_checker` uses a 256-cycle completion bound as a **test environment assumption**, not an AXI4-Lite latency requirement. Its procedural checks are active; optional `FULL_SV` concurrent assertions are not enabled.

| Test | DUT/configuration | Independent checks |
| --- | --- | --- |
| `sram_test` (copied) | SRAM, 1,024 words | First/middle/last words, all 16 strobes, reset retention; 20 reported checks. |
| `axi_slave_test` (copied) | Slave + SRAM, default base/depth | AW-first, W-first, simultaneous, B/R stalls, WSTRB, address errors; 58 reported checks. |
| `axi_master_test` (copied) | Master + delay gates + slave + SRAM, default | 26 transactions through all five delayed channels, error propagation, protocol checker pairing. |
| `axi_reset_test` (copied) | Slave + SRAM, depth 3 | Partial AW/W reset, stalled R/B reset, committed-memory retention, simultaneous read/write priority, invalid upper bound. |
| `master_responder_test` (new) | Master vs controlled responder, no SRAM | Independent AW/W/AR stalls; stable VALID/payload; AW-first, W-first and together acceptance; delayed B/R responses, error/data propagation, no duplicate completion, reset abort/recovery. |
| `slave_model_test` (new) | Direct slave + SRAM, base `0x30000000`, depth 7 | Independent 7-word byte-lane model; 16 WSTRB masks including zero, all AW/W orders, B/R backpressure, pairing, boundaries, below/above/unaligned errors with no SRAM enable, readback after invalid writes. |
| `standalone_top_test` (new) | Integrated top, base `0x20000000`, depth 5 | CPU-independent requests, independent memory model, read/write/readback, 16 strobes, first/last and invalid addresses, idle reset and retention. |

The legacy `axi_protocol_checker` monitors AW/W/B/AR/R VALID and payload stability while stalled, response pairing, and bounded completion. The direct and integrated new tests use four-state `!==` comparisons and `$fatal` on mismatch. The master-only responder drives only slave-side bus signals; the direct-slave harness drives only master-side bus signals, avoiding conflicting drivers.

The present regression does not measure line/branch/toggle coverage, execute optional concurrent SVA, prove unbounded liveness, or validate full AXI4-Lite compliance. Out-of-scope architectures and hardware work are listed in the README.
