`ifndef TEST_UTILITIES_SV
`define TEST_UTILITIES_SV

// Task to check a condition.
// The message is passed as a reg [1023:0] which should hold a literal string.
task pretty_print_assert_cond;
  input condition;
  input [1023:0] msg;
  begin
    if (!condition) begin
      $display("\033[0;31mAssertion Failed: %s\033[0m", msg);
    end else begin
      $display("\033[0;32mAssertion Passed: %s\033[0m", msg);
    end
  end
endtask

// Task to compare two 8-bit values.
task pretty_print_assert_8bit;
  input [7:0] actual;
  input [7:0] expected;
  input [1023:0] msg;
  begin
    if (actual !== expected) begin
      $display("\033[0;31mAssertion Failed: %s. Actual: %b, Expected: %b\033[0m", msg, actual, expected);
    end else begin
      $display("\033[0;32mAssertion Passed: %s\033[0m", msg);
    end
  end
endtask

// Task to compare two 32-bit vectors.
task pretty_print_assert_vec;
  input [31:0] actual;
  input [31:0] expected;
  input [1023:0] msg;
  begin
    if (actual !== expected) begin
      $display("\033[0;31mAssertion Failed: %s. Actual: %0b, Expected: %0b\033[0m", msg, actual, expected);
    end else begin
      $display("\033[0;32mAssertion Passed: %s\033[0m", msg);
    end
  end
endtask

`endif