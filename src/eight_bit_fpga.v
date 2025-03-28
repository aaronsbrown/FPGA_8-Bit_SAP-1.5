module eight_bit_fpga (
    input wire clk,
    input wire reset_n, 
    output wire [7:0] out_val
);
    
    // Invert active-low reset
    wire reset = ~reset_n;
    
    // Shared bus for data transfer
    wire [7:0] bus;


    wire load_a, load_b, load_out, load_ir;
    wire inc_pc, load_pc, load_mar, we_ram, oe_ram;
    wire [3:0] alu_op;
    wire [7:0] instruction;


    wire [7:0] a_out, b_out, alu_out, ram_out, pc_out, ir_out, mar_out;

    a_register u_a_reg (
        .clk(clk),
        .reset(reset),
        .load(load_a),
        .data_in(bus),
        .data_out(a_out)
    );

    b_register u_b_reg (
        .clk(clk),
        .reset(reset),
        .load(load_b),
        .data_in(bus),
        .data_out(b_out)
    );

    output_register u_out_reg (
        .clk(clk),
        .reset(reset),
        .load(load_out),
        .data_in(bus),
        .data_out(out_val)
    );

    alu u_alu (
        .a(a_out),
        .b(b_out),
        .alu_op(alu_op),
        .result(alu_out)
    );

    instruction_register u_ir_reg (
        .clk(clk),
        .reset(reset),
        .load(load_ir),
        .data_in(bus),
        .data_out(ir_out)
    );
    program_counter u_pc (
        .clk(clk),
        .reset(reset),
        .load(load_pc),
        .inc(inc_pc),
        .data_in(bus),
        .data_out(pc_out)
    );

    memory_address_register u_mar_reg (
        .clk(clk),
        .reset(reset),
        .load(load_mar),
        .data_in(bus),
        .data_out(mar_out)
    );

    ram u_ram (
        .clk(clk),
        .we(we_ram),
        .oe(oe_ram),
        .address(mar_out),
        .data_in(bus),
        .data_out(ram_out)
    );

    control_unit u_control_unit (
        .clk(clk),
        .reset(reset),
        .instruction(ir_out),
        .load_a(load_a),
        .load_b(load_b),
        .load_out(load_out),
        .load_ir(load_ir),
        .inc_pc(inc_pc),
        .load_pc(load_pc),
        .load_mar(load_mar),
        .we_ram(we_ram),
        .oe_ram(oe_ram),
        .alu_op(alu_op)
    );

    // Bus logic (TBD): multiplexer / tri-state-style selectors between bus and internal outputs
    // TODO: Add bus arbitration logic

endmodule
