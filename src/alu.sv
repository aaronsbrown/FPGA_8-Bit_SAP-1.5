`include "include/microarch_defs.sv"

module alu (
    input logic clk,
    input logic reset,
    input logic [7:0] a_in,
    input logic [7:0] b_in,
    input logic [1:0] alu_op,
    output logic [7:0] latched_result,
    output logic zero_flag,
    output logic carry_flag,
    output logic negative_flag
);
    
    // Local variables for intermediate calculation within this block
    logic [8:0] comb_arith_result_i; // 9 bits to accommodate carry
    logic [7:0] comp_logic_result_i;
    logic       comb_carry_out_i;
    logic [7:0] comb_result_final_i;

    always_comb begin
        
        // default all values to rpevent latch inference
        comb_arith_result_i = 9'b0;
        comp_logic_result_i = 8'b0;
        comb_carry_out_i = 1'b0;
        comb_result_final_i = 8'b0;
        
        case (alu_op)
            ALU_ADD: comb_arith_result_i = {1'b0, a_in} + {1'b0, b_in};
            ALU_SUB: comb_arith_result_i = {1'b0, a_in} - {1'b0, b_in};
            ALU_AND: comp_logic_result_i = a_in & b_in;
            ALU_OR:  comp_logic_result_i = a_in | b_in;
            default: ;
        endcase
        
        if (alu_op == ALU_ADD || alu_op == ALU_SUB) begin
            comb_carry_out_i = comb_arith_result_i[8]; // Check for carry out
            comb_result_final_i = comb_arith_result_i[7:0]; 
        end else begin
            comb_carry_out_i = 1'b0;
            comb_result_final_i = comp_logic_result_i;
        end
    end 
    
    // Carry Flag = 1 means No Borrow occurred (unsigned A >= B).
    // Carry Flag = 0 means a Borrow occurred (unsigned A < B).
    assign carry_flag = comb_carry_out_i;
    assign zero_flag = (comb_result_final_i == 8'b0);
    assign negative_flag = comb_result_final_i[7];
    
    always_ff @(posedge clk) begin
        if (reset) begin
            latched_result <= 8'b0;
        end else begin
            latched_result <= comb_result_final_i;
        end
    end

endmodule