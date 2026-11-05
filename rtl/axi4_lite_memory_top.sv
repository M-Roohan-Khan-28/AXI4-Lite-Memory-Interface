// Standalone integration of the unchanged SoC AXI4-Lite master, slave, and SRAM.
module axi4_lite_memory_top #(
  parameter logic [31:0] BASE_ADDR = 32'h10000000,
  parameter int SRAM_DEPTH = 1024,
  parameter int ADDR_BITS = (SRAM_DEPTH > 1 ? $clog2(SRAM_DEPTH) : 1)
)(
  input  logic clk, reset_n,
  input  logic req_valid, req_write,
  input  logic [31:0] req_addr, req_wdata,
  input  logic [3:0] req_wstrb,
  output logic req_ready, response_valid, response_error,
  output logic [31:0] response_data
);
  axi_lite_if bus(clk, reset_n);
  logic sram_en, sram_we;
  logic [ADDR_BITS-1:0] sram_addr;
  logic [31:0] sram_wdata, sram_rdata;
  logic [3:0] sram_wstrb;

  axi_lite_master master(
    .clk(clk), .reset_n(reset_n),
    .req_valid(req_valid), .req_write(req_write),
    .req_addr(req_addr), .req_wdata(req_wdata), .req_wstrb(req_wstrb),
    .req_ready(req_ready), .response_valid(response_valid),
    .response_error(response_error), .response_data(response_data), .axi(bus)
  );
  axi_lite_slave #(.BASE_ADDR(BASE_ADDR), .SRAM_DEPTH(SRAM_DEPTH)) slave(
    .axi(bus), .sram_en(sram_en), .sram_we(sram_we),
    .sram_addr(sram_addr), .sram_wdata(sram_wdata), .sram_wstrb(sram_wstrb),
    .sram_rdata(sram_rdata)
  );
  sram #(.DEPTH(SRAM_DEPTH)) memory(
    .clk(clk), .reset_n(reset_n), .en(sram_en), .we(sram_we),
    .addr(sram_addr), .wdata(sram_wdata), .wstrb(sram_wstrb), .rdata(sram_rdata)
  );
endmodule
