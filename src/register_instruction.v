module register_instruction (
    input             clk,
    input             reset,
    input             load,
    input    [7:0]  data_in,
    output  reg [3:0] opcode,
    output  reg [3:0] operand
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            opcode <= 0;
            operand <= 0;
        end else if (load) begin
            opcode <= data_in[7:4];
            operand <= data_in[3:0];
        end
    end

endmodule
