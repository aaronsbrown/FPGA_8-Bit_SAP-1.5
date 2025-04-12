import arch_defs_pkg::*;

module register_instruction (
    input   logic                       clk,
    input   logic                       reset,
    input   logic                       load,
    input   logic   [DATA_WIDTH-1:0]    data_in,
    output  opcode_t                    opcode,
    output  logic   [OPERAND_WIDTH-1:0] operand
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
