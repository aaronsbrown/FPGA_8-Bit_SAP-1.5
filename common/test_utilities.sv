`ifndef TEST_UTILITIES_SV
`define TEST_UTILITIES_SV

task automatic pretty_print_assert_cond(input bit condition, input string msg);
  if (!condition) begin
    $display("\033[0;31mAssertion Failed: %s\033[0m", msg);
  end else begin
    $display("\033[0;32mAssertion Passed: %s\033[0m", msg);
  end
endtask

task automatic pretty_print_assert_8bit(
    input logic [7:0] actual, 
    input logic [7:0] expected, 
    input string msg
);
  if (actual !== expected) begin
    $display("\033[0;31mAssertion Failed: %s. Actual: %b, Expected: %b\033[0m", msg, actual, expected);
  end else begin
    $display("\033[0;32mAssertion Passed: %s\033[0m", msg);
  end
endtask

`define pretty_print_assert_vec(actual, expected, msg) \
  if ((actual) !== (expected)) begin \
    $display("\033[0;31mAssertion Failed: %s. Actual: %0b, Expected: %0b\033[0m", msg, actual, expected); \
  end else begin \
    $display("\033[0;32mAssertion Passed: %s\033[0m", msg); \
  end

`endif