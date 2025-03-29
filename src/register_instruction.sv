`include "include/microarch_defs.sv"

module register_instruction (
    input   logic           clk,
    input   logic           reset,
    input   logic           load,
    input   logic   [7:0]   data_in,
    output  logic   [3:0]   opcode,
    output  logic   [3:0]   operand
);

    instruction_t instruction;

    always_ff @(posedge clk) begin
        if (reset) 
            instruction <= '0;
        else if (load) 
            instruction <= instruction_t'(data_in);
    end

    assign opcode = instruction.opcode;
    assign operand = instruction.operand;

endmodule
