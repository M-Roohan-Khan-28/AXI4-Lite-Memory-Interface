`timescale 1ns/1ps
// Direct slave/SRAM harness with a reference byte-lane memory independent of DUT RAM.
module slave_model_test;
  localparam logic [31:0] BASE = 32'h30000000;
  localparam int DEPTH = 7;
  bit clk = 0, reset_n = 0;
  always #5 clk = ~clk;
  axi_lite_if bus(clk, reset_n);
  logic en, we;
  logic [2:0] addr;
  logic [31:0] wd, rd;
  logic [3:0] strb;
  logic [31:0] model[0:DEPTH-1];
  bit invalid_access = 0;
  int checks = 0;
  axi_lite_slave #(.BASE_ADDR(BASE), .SRAM_DEPTH(DEPTH)) dut(bus, en, we, addr, wd, strb, rd);
  sram #(.DEPTH(DEPTH)) memory(clk, reset_n, en, we, addr, wd, strb, rd);
  axi_protocol_checker protocol(bus);

  always @(posedge clk) if (reset_n && invalid_access && en)
    $fatal(1, "invalid address enabled SRAM");

  task automatic send_aw(input logic [31:0] address, input int delay_cycles);
    repeat (delay_cycles) @(negedge clk);
    bus.awaddr = address; bus.awvalid = 1;
    do @(posedge clk); while (!bus.awready);
    @(negedge clk); bus.awvalid = 0;
  endtask
  task automatic send_w(input logic [31:0] data, input logic [3:0] strobes,
                        input int delay_cycles);
    repeat (delay_cycles) @(negedge clk);
    bus.wdata = data; bus.wstrb = strobes; bus.wvalid = 1;
    do @(posedge clk); while (!bus.wready);
    @(negedge clk); bus.wvalid = 0;
  endtask
  task automatic write_bus(input logic [31:0] address, data,
                           input logic [3:0] strobes, input int order,
                           input bit want_error);
    @(negedge clk);
    invalid_access = want_error;
    case (order)
      0: fork send_aw(address, 0); send_w(data, strobes, 4); join
      1: fork send_aw(address, 4); send_w(data, strobes, 0); join
      default: fork send_aw(address, 0); send_w(data, strobes, 0); join
    endcase
    wait (bus.bvalid);
    repeat (3) begin
      @(negedge clk);
      if (!bus.bvalid || bus.bresp !== (want_error ? 2'b10 : 2'b00))
        $fatal(1, "stalled B changed addr=%h", address);
      checks++;
    end
    bus.bready = 1;
    @(negedge clk); bus.bready = 0;
    if (bus.bvalid) $fatal(1, "duplicate B response");
    invalid_access = 0;
    checks++;
  endtask
  task automatic read_bus(input logic [31:0] address,
                          input logic [31:0] want_data, input bit want_error);
    @(negedge clk);
    invalid_access = want_error;
    bus.araddr = address; bus.arvalid = 1;
    do @(posedge clk); while (!bus.arready);
    @(negedge clk); bus.arvalid = 0;
    wait (bus.rvalid);
    repeat (3) begin
      @(negedge clk);
      if (!bus.rvalid || bus.rresp !== (want_error ? 2'b10 : 2'b00) ||
          bus.rdata !== want_data)
        $fatal(1, "stalled R addr=%h got=%h expected=%h", address, bus.rdata, want_data);
      checks++;
    end
    bus.rready = 1;
    @(negedge clk); bus.rready = 0;
    if (bus.rvalid) $fatal(1, "duplicate R response");
    invalid_access = 0;
    checks++;
  endtask
  task automatic write_model(input int index, input logic [31:0] data,
                             input logic [3:0] strobes, input int order);
    write_bus(BASE + 4*index, data, strobes, order, 0);
    for (int lane = 0; lane < 4; lane++)
      if (strobes[lane]) model[index][8*lane +: 8] = data[8*lane +: 8];
  endtask
  task automatic read_model(input int index);
    read_bus(BASE + 4*index, model[index], 0);
  endtask

  initial begin
    bus.awvalid = 0; bus.wvalid = 0; bus.arvalid = 0;
    bus.bready = 0; bus.rready = 0;
    bus.awaddr = 0; bus.awprot = 0; bus.wdata = 0; bus.wstrb = 0;
    bus.araddr = 0; bus.arprot = 0;
    repeat (3) @(negedge clk); reset_n = 1;
    for (int i = 0; i < DEPTH; i++) begin
      model[i] = 32'hC0102030 + 32'h01010101*i;
      write_model(i, model[i], 4'hf, i%3);
      read_model(i);
    end
    for (int s = 0; s < 16; s++) begin
      write_model(3, 32'h87654300 + s, 4'(s), s%3);
      read_model(3);
    end
    read_model(0); read_model(DEPTH-1);
    write_bus(BASE-4, 32'hFFFFFFFF, 4'hf, 0, 1);
    read_bus(BASE-4, 0, 1);
    write_bus(BASE+4*DEPTH, 32'hFFFFFFFF, 4'hf, 1, 1);
    read_bus(BASE+4*DEPTH, 0, 1);
    write_bus(BASE+1, 32'hFFFFFFFF, 4'hf, 2, 1);
    read_bus(BASE+1, 0, 1);
    for (int i = 0; i < DEPTH; i++) read_model(i);
    if (protocol.writes != 26 || protocol.reads != 35)
      $fatal(1, "response pairing writes=%0d reads=%0d", protocol.writes, protocol.reads);
    checks++;
    $display("SLAVE_MODEL_PASS checks=%0d writes=%0d reads=%0d",
             checks, protocol.writes, protocol.reads);
    $finish;
  end
  initial begin #200000; $fatal(1, "slave model timeout"); end
endmodule
