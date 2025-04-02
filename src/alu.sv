`include "include/microarch_defs.sv"

module alu (
    input logic clk,
    input logic reset,
    input logic [7:0] a_in,
    input logic [7:0] b_in,
    input logic [1:0] alu_op,
    output logic [7:0] result_out,
    output logic zero_flag,
    output logic carry_flag,
    output logic negative_flag
);
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            result_out <= 8'b0;
            carry_flag <= 1'b0;
            zero_flag <= 1'b0;
        end else begin
            case (alu_op)
                ALU_ADD: begin
                    {carry_flag, result_out} <= a_in + b_in;
                end
                ALU_SUB: begin
                    {carry_flag, result_out} <= a_in - b_in;
                end
                ALU_AND: begin
                    result_out <= a_in & b_in;
                    carry_flag <= 1'b0; // No carry for AND operation
                end
                ALU_OR: begin
                    result_out <= a_in | b_in;
                    carry_flag <= 1'b0; // No carry for OR operation
                end
                default: begin
                    result_out <= 8'b0;
                    carry_flag <= 1'b0;
                end
            endcase

            // Set zero flag if result is zero
            zero_flag <= (result_out == 8'b0);
            // Set negative flag if result is negative (MSB is 1)
            negative_flag <= result_out[7];
        
        end
    end

endmodule