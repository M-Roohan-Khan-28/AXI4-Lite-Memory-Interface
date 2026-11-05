`timescale 1ns/1ps
// Master-only harness. This responder owns only the slave-side AXI signals.
module master_responder_test;
  bit clk = 0, reset_n = 0;
  always #5 clk = ~clk;
  logic req_valid = 0, req_write = 0;
  logic [31:0] req_addr = 0, req_wdata = 0;
  logic [3:0] req_wstrb = 0;
  logic req_ready, response_valid, response_error;
  logic [31:0] response_data;
  axi_lite_if bus(clk, reset_n);
  axi_lite_master dut(clk, reset_n, req_valid, req_write, req_addr, req_wdata,
                      req_wstrb, req_ready, response_valid, response_error,
                      response_data, bus);
  axi_protocol_checker protocol(bus);
  int checks = 0;

  task automatic request(input bit is_write, input logic [31:0] address,
                         input logic [31:0] data, input logic [3:0] strobes);
    @(negedge clk);
    while (!req_ready) @(negedge clk);
    req_valid = 1; req_write = is_write; req_addr = address;
    req_wdata = data; req_wstrb = strobes;
    @(posedge clk);
    if (!req_ready) $fatal(1, "request not accepted");
    @(negedge clk); req_valid = 0;
  endtask

  task automatic send_write(input int order, input logic [1:0] status,
                            input logic [3:0] strobes);
    logic [31:0] address, data;
    address = 32'h10000000 + 4*order;
    data = 32'hA13B5C00 + order;
    request(1, address, data, strobes);
    repeat (3) begin
      @(negedge clk);
      if (!bus.awvalid || !bus.wvalid || bus.awaddr !== address ||
          bus.wdata !== data || bus.wstrb !== strobes || bus.awprot !== 0 ||
          bus.bready || response_valid) $fatal(1, "stalled write payload changed");
      checks++;
    end
    case (order)
      0: begin // AW accepted first.
        bus.awready = 1; @(negedge clk); bus.awready = 0;
        if (bus.awvalid || !bus.wvalid) $fatal(1, "AW-first sequencing");
        repeat (2) @(negedge clk);
        bus.wready = 1; @(negedge clk); bus.wready = 0;
      end
      1: begin // W accepted first.
        bus.wready = 1; @(negedge clk); bus.wready = 0;
        if (bus.wvalid || !bus.awvalid) $fatal(1, "W-first sequencing");
        repeat (2) @(negedge clk);
        bus.awready = 1; @(negedge clk); bus.awready = 0;
      end
      default: begin
        bus.awready = 1; bus.wready = 1;
        @(negedge clk); bus.awready = 0; bus.wready = 0;
      end
    endcase
    if (bus.awvalid || bus.wvalid || !bus.bready) $fatal(1, "write handshakes incomplete");
    repeat (3) begin
      @(negedge clk);
      if (response_valid || !bus.bready) $fatal(1, "early write completion");
      checks++;
    end
    bus.bresp = status; bus.bvalid = 1;
    @(negedge clk); bus.bvalid = 0;
    if (!response_valid || response_error !== (status != 0))
      $fatal(1, "B response propagation");
    checks++;
    repeat (2) @(negedge clk);
    if (response_valid || !req_ready) $fatal(1, "duplicate completion or no idle");
    checks++;
  endtask

  task automatic send_read(input logic [31:0] address,
                           input logic [31:0] data, input logic [1:0] status);
    request(0, address, 0, 0);
    repeat (4) begin
      @(negedge clk);
      if (!bus.arvalid || bus.araddr !== address || bus.arprot !== 0 ||
          bus.rready || response_valid) $fatal(1, "stalled AR payload changed");
      checks++;
    end
    bus.arready = 1; @(negedge clk); bus.arready = 0;
    if (bus.arvalid || !bus.rready) $fatal(1, "AR handshake incomplete");
    repeat (3) @(negedge clk);
    if (response_valid) $fatal(1, "early read completion");
    bus.rdata = data; bus.rresp = status; bus.rvalid = 1;
    @(negedge clk); bus.rvalid = 0;
    if (!response_valid || response_error !== (status != 0) || response_data !== data)
      $fatal(1, "R response propagation");
    checks++;
    repeat (2) @(negedge clk);
    if (response_valid || !req_ready) $fatal(1, "duplicate read completion");
    checks++;
  endtask

  initial begin
    bus.awready = 0; bus.wready = 0; bus.bvalid = 0; bus.bresp = 0;
    bus.arready = 0; bus.rvalid = 0; bus.rdata = 0; bus.rresp = 0;
    repeat (3) @(negedge clk); reset_n = 1;
    send_write(0, 0, 4'hf);
    send_write(1, 2'b10, 4'h5);
    send_write(2, 0, 4'h0);
    send_read(32'h10000000, 32'h12345678, 0);
    send_read(32'h10000004, 0, 2'b10);
    if (protocol.writes != 3 || protocol.reads != 2)
      $fatal(1, "response pairing count writes=%0d reads=%0d", protocol.writes, protocol.reads);
    checks++;
    // Abort an unaccepted AR and recover with a new request.
    request(0, 32'h10000008, 0, 0);
    repeat (2) @(negedge clk);
    reset_n = 0;
    repeat (2) @(negedge clk);
    if (bus.arvalid || response_valid || req_ready) $fatal(1, "master reset abort");
    checks++;
    reset_n = 1;
    send_read(32'h1000000C, 32'h55AA33CC, 0);
    $display("MASTER_RESPONDER_PASS checks=%0d writes=3 reads=3", checks);
    $finish;
  end
  initial begin #100000; $fatal(1, "master responder timeout"); end
endmodule
