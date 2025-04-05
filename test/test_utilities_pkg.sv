`ifndef UUT_PATH
  `define UUT_PATH uut // Default fallback
`endif

package test_utils_pkg;

  // Task to compare two 32-bit vectors.
  task pretty_print_assert_vec;
    input [31:0] actual;
    input [31:0] expected;
    input string msg;
    begin
      if (actual !== expected) begin
        $display("\033[0;31mAssertion Failed: %s. Actual: %0b, Expected: %0b\033[0m", msg, actual, expected);
      end else begin
        $display("\033[0;32mAssertion Passed: %s\033[0m", msg);
      end
    end
  endtask

  parameter int RAM_SIZE_BYTES = 16; // TODO MOVE TO constants package
  task clear_ram;
    input int start_addr;
    input int end_addr;
    begin
      for (int i = start_addr; i <= end_addr; i++) begin
        if (i < RAM_SIZE_BYTES) begin
          `UUT_PATH.u_ram.ram[i] = 8'h00;
        end else begin
          $display("Warning: clear_ram attempted to access out-of-bounds address %0d", i);
        end
      end
    end
  endtask
  

  // Task to run simulation until halt is asserted or a cycle timeout occurs
  task run_until_halt;
    input int max_cycles;
    int cycle;
    begin
      cycle = 0;
      while (`UUT_PATH.halt == 0 && cycle < max_cycles) begin
        @(posedge clk);
        cycle++;
      end
      if (cycle >= max_cycles) begin
        $display("\033[0;31mSimulation timed out. HALT signal not asserted after %0d cycles.\033[0m", cycle);
        $error("Simulation timed out.");
        $finish;
      end else begin
        $display("\033[0;32mSimulation completed. HALT signal received after %0d cycles.\033[0m", cycle);
      end
    end
  endtask

  task inspect_register;
    input [7:0] actual;
    input [7:0] expected;
    input string name;
    begin
      pretty_print_assert_vec(actual, expected, {name, " register check"});
    end
  endtask

  task reset_and_wait;
    input int cycles;
    begin
      
      reset = 1;
      
      @(posedge clk);
      
      @(negedge clk);
      reset = 0;
      
      repeat (cycles) @(posedge clk);
    end
  endtask

endpackage : test_utils_pkg
