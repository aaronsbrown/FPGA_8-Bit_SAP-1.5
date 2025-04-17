import arch_defs_pkg::*;


`ifndef UUT_PATH
  `define UUT_PATH uut // Default fallback
`endif

package test_utils_pkg;

  // Task to compare two 32-bit vectors.
  task pretty_print_assert_vec;
    // Keep using fixed width arguments
    input [31:0] actual;
    input [31:0] expected;
    input string msg;
    begin
      // Comparison '===' works correctly even if actual vectors are smaller
      // (they get implicitly zero-extended).
      if (actual !== expected) begin
        $display("\033[0;31mAssertion Failed: %s. Actual: %h, Expected: %h\033[0m", msg, actual, expected); // Use %h for hex
      end else begin
        $display("\033[0;32mAssertion Passed: %s\033[0m", msg);
      end
    end
  endtask

  task clear_ram;
    input int start_addr;
    input int end_addr;
    begin
      for (int i = start_addr; i <= end_addr; i++) begin
        if (i < RAM_DEPTH) begin
          `UUT_PATH.u_ram.mem[i] = 8'h00;
        end else begin
          $display("Warning: clear_ram attempted to access out-of-bounds address %0d (RAM Depth: %0d)", i, RAM_DEPTH);
        end
      end
    end
  endtask
  

  // Task to run simulation until halt is asserted or a cycle timeout occurs
   task run_until_halt;
    input int max_cycles;
    int cycle;
    begin // Task begin
      cycle = 0;
      while (cycle < max_cycles) begin 
        #1ps; 
        if (`UUT_PATH.halt == 1) begin 
            $display("HALT signal detected high at start of cycle %0d.", cycle + 1);
            break; 
        end 
        @(posedge clk); // Wait for next edge if not halted
        cycle++;
      end 

      #1ps; // Allow final state signals to settle
      if (`UUT_PATH.halt == 0 && cycle >= max_cycles) begin // If timeout begin
        $display("\033[0;31mSimulation timed out. HALT signal not asserted after %0d cycles.\033[0m", cycle);
        $error("Simulation timed out.");
        $finish;
      end 
      else begin // Else (halt detected or finished cycles but halt is high) begin
        $display("\033[0;32mSimulation run completed (halt detected or max cycles reached while potentially halting). Cycles run: %0d\033[0m", cycle);
      end 
    end // Task end
  endtask

  task inspect_register;
    // Use fixed width for task arguments
    input [31:0] actual;
    input [31:0] expected;
    input string name;
    input int expected_width;
    logic [31:0] mask;
  begin
      // Create a mask to compare only relevant bits
      mask = (expected_width == 32) ? 32'hFFFFFFFF : (32'h1 << expected_width) - 1;
      // Compare only the lower 'expected_width' bits
      if ((actual & mask) !== (expected & mask)) begin
           $display("\033[0;31mAssertion Failed: %s (%0d bits). Actual: %h, Expected: %h\033[0m",
                    name, expected_width, actual & mask, expected & mask);
      end else begin
           $display("\033[0;32mAssertion Passed: %s (%0d bits) = %h\033[0m",
                    name, expected_width, actual & mask);
      end
      // Call the original pretty_print_assert_vec if you want the full binary view too
      // pretty_print_assert_vec(actual & mask, expected & mask, {name, " register check"});
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
