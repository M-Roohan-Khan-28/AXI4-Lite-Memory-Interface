# Version 1 specification

This project extracts the 32-bit AXI4-Lite memory path from `RV32I-AXI4-Lite-SoC` at source commit `ceacccb687b39af045431f2ce4d1205276780b6a`. The extracted master, slave, interface, and SRAM are byte-for-byte copies; `axi4_lite_memory_top` is the new integration component. No CPU, DMA, burst transfer, interconnect, or UVM environment is included.

## Request interface and master

The top accepts `req_valid`, `req_write`, byte address, 32-bit write data and four WSTRB bits at a rising clock edge when `req_ready` is high. `req_ready` is high only while the master is idle and reset is inactive. One request can be in flight. The master launches AW and W together for a write, but keeps their VALID signals and payloads independently until each is accepted. It launches AR for a read. It then waits for B or R, maps any non-OKAY response to `response_error`, and gives a one-cycle `response_valid` completion. There is no completion-ready input; the requester must observe that pulse. `response_data` is meaningful only for a completed read; a write leaves the prior data value unchanged. The DONE state prevents the request held through completion from being accepted at the completion edge. The requester should lower `req_valid` after acceptance unless it intends a later request.

## Slave and memory

The slave accepts AW and W independently, storing one of each until it can issue a write. It can also buffer an AR request while a write is pending. A complete write wins the single SRAM port over a queued read. B and R VALID/payload stay held until the corresponding READY handshake. At most one write response and one read response can be pending in this implementation. AWPROT and ARPROT are carried as interface signals; the slave does not interpret them. This design makes no claim about AXI4 bursts, IDs, exclusive accesses, or general interconnect arbitration.

The SRAM has a 32-bit word and four little-endian byte lanes. `WSTRB[i]` updates bits `[8*i +: 8]`; zero strobe is a legal no-op write with an OKAY response. Reads are synchronous. The array and SRAM read-data register are uninitialized at power-up, so tests write a word before checking it. At a simultaneous direct SRAM read/write edge, the registered read value is the old word (read-first semantics).

Default `BASE_ADDR=0x10000000` and `SRAM_DEPTH=1024` give legal word addresses `0x10000000` through `0x10000FFC`. A legal address is 4-byte aligned, at or above BASE_ADDR, and has a word index below SRAM_DEPTH. Invalid or unaligned writes return `SLVERR=2'b10` without SRAM enable; invalid reads return zero with SLVERR. The master reduces any nonzero B/R response to `response_error=1`. Configurations require positive depth, word-aligned base, and a region that fits within the 32-bit address space. The index width is at least one and is `$clog2(SRAM_DEPTH)` otherwise. Non-power-of-two depths are supported by the slave's full-address range check; depth 3 and depth 5 are exercised in tests. Widths and clocking are fixed at 32-bit and one shared clock.

Reset is synchronous active-low and must cross a rising edge. It clears master/slave control, buffered AW/W/AR and outstanding B/R state, canceling incomplete bus transfers. A write already issued to SRAM before reset remains stored. Reset does not clear SRAM contents or read-data register. Reset while a write is partly accepted does not commit that partial write.

## Source-document reconciliation

The SoC README describes independent slave AW/W acceptance, byte strobes, reset retention, and one master request in flight; the inspected RTL implements those behaviors. Its generic bus statement is bounded here by the actual implementation: the master emits AW and W together and exposes all four WSTRB bits, while the **slave** can accept AW and W in either order. The master has no B/R backpressure control from its requester and no hardware timeout. The testbench's bounded completion timeout is an environment guard, not an AXI4-Lite protocol latency rule. No source RTL correction was made during extraction.
