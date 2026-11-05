`timescale 1ns/1ps
module standalone_top_test;
  localparam logic [31:0] BASE = 32'h20000000;
  localparam int DEPTH = 5;
  bit clk = 0, reset_n = 0;
  always #5 clk = ~clk;
  logic req_valid = 0, req_write = 0;
  logic [31:0] req_addr = 0, req_wdata = 0;
  logic [3:0] req_wstrb = 0;
  logic req_ready, response_valid, response_error;
  logic [31:0] response_data;
  logic [31:0] expected[0:DEPTH-1];
  int checks = 0;

  axi4_lite_memory_top #(.BASE_ADDR(BASE), .SRAM_DEPTH(DEPTH)) dut(.*);

  task automatic transact(input bit is_write, input logic [31:0] address,
                          input logic [31:0] data, input logic [3:0] strobes,
                          input bit want_error, input logic [31:0] want_data = 0);
    @(negedge clk);
    while (!req_ready) @(negedge clk);
    req_valid = 1;
    req_write = is_write;
    req_addr = address;
    req_wdata = data;
    req_wstrb = strobes;
    @(posedge clk);
    if (!req_ready) $fatal(1, "request was not accepted");
    @(negedge clk);
    req_valid = 0;
    while (!response_valid) @(negedge clk);
    if (response_error !== want_error)
      $fatal(1, "response error addr=%h write=%b got=%b expected=%b",
             address, is_write, response_error, want_error);
    checks++;
    if (!is_write && response_data !== want_data)
      $fatal(1, "read addr=%h got=%h expected=%h", address, response_data, want_data);
    if (!is_write) checks++;
  endtask

  task automatic write_model(input int word_index, input logic [31:0] data,
                             input logic [3:0] strobes);
    transact(1, BASE + 4*word_index, data, strobes, 0);
    for (int lane = 0; lane < 4; lane++)
      if (strobes[lane]) expected[word_index][8*lane +: 8] = data[8*lane +: 8];
  endtask

  task automatic read_model(input int word_index);
    transact(0, BASE + 4*word_index, 0, 0, 0, expected[word_index]);
  endtask

  initial begin
    repeat (3) @(negedge clk);
    reset_n = 1;
    // Initialize every word; SRAM power-up contents are deliberately unspecified.
    for (int i = 0; i < DEPTH; i++) begin
      expected[i] = 32'h10203040 ^ (32'h01010101 * i);
      write_model(i, expected[i], 4'hf);
      read_model(i);
    end
    // Independent byte-lane reference model, including zero-strobe no-op.
    for (int s = 0; s < 16; s++) begin
      write_model(2, 32'hA1B2C300 + s, 4'(s));
      read_model(2);
    end
    // First/last legal words and invalid lower, upper, and unaligned addresses.
    read_model(0);
    read_model(DEPTH-1);
    transact(1, BASE-4, 32'hFFFFFFFF, 4'hf, 1);
    transact(0, BASE-4, 0, 0, 1, 0);
    transact(1, BASE+4*DEPTH, 32'hFFFFFFFF, 4'hf, 1);
    transact(0, BASE+4*DEPTH, 0, 0, 1, 0);
    transact(1, BASE+1, 32'hFFFFFFFF, 4'hf, 1);
    transact(0, BASE+1, 0, 0, 1, 0);
    read_model(0);
    read_model(DEPTH-1);
    // Reset control while idle; initialized SRAM words must be retained.
    @(negedge clk); reset_n = 0;
    repeat (2) @(negedge clk);
    if (response_valid || req_ready) $fatal(1, "reset did not clear interface state");
    checks++;
    reset_n = 1;
    for (int i = 0; i < DEPTH; i++) read_model(i);
    $display("STANDALONE_TOP_PASS checks=%0d", checks);
    $finish;
  end
  initial begin #100000; $fatal(1, "standalone top timeout"); end
endmodule
