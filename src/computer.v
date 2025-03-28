module computer (
    input wire clk,
    input wire reset, 
    output wire [7:0] out_val
);
    
    
    reg [2:0] state;
    localparam STATE_0 = 3'b000,
        STATE_1 = 3'b001,
        STATE_2 = 3'b010,
        STATE_3 = 3'b011;
    
    // Shared bus for data transfer
    reg [7:0] bus;
    
    // Simple Registers & control signals
    wire [7:0] a_out, b_out, temp_out;
    reg load_a, load_b, load_temp;
    reg enable_a, enable_b, enable_temp;

    register_nbit #( .N(8) ) u_register_temp (
        .clk(clk),
        .reset(reset),
        .load(load_temp),
        .data_in(bus),
        .latched_data(temp_out)
    );

    register_nbit #( .N(8) ) u_register_A (
        .clk(clk),
        .reset(reset),
        .load(load_a),
        .data_in(bus),
        .latched_data(a_out)
    );

    register_nbit #( .N(8) ) u_register_B (
        .clk(clk),
        .reset(reset),
        .load(load_b),
        .data_in(bus),
        .latched_data(b_out)
    );

    assign bus = (enable_temp) ? temp_out :
                  (enable_a) ? a_out : 
                  (enable_b) ? b_out : 
                  8'b0;
    
    assign out_val = bus;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= STATE_0;
            
            load_a <= 0;
            load_b <= 0;
            load_temp <= 0;
            
            enable_a <= 0;
            enable_b <= 0;
            enable_temp <= 0;
        end else begin
            case (state)
                STATE_0: begin
                    enable_temp <= 1;
                    load_a <= 1;
                    state <= STATE_1;
                end
                STATE_1: begin
                    enable_temp <= 0;
                    load_a <= 0;
                    state <= STATE_2;
                end
                STATE_2: begin 
                    enable_a <= 1;
                    state <= STATE_3;
                end
                STATE_3: begin 
                    state <= STATE_0;
                end
                default: state <= STATE_0;
            endcase
        end
    end


    
    // output_register u_out_reg (
    //     .clk(clk),
    //     .reset(reset),
    //     .load(load_out),
    //     .data_in(bus),
    //     .data_out(out_val)
    // );

    // alu u_alu (
    //     .clk(clk),
    //     .reset(reset),
    //     .a(a_out),
    //     .b(b_out),
    //     .subtract(subtract),
    //     .flag_enable(flag_enable),
    //     .result(alu_out),
    //     .flag_carry(flag_carry),
    //     .flag_zero(flag_zero)
    // );

    // instruction_register u_ir_reg (
    //     .clk(clk),
    //     .reset(reset),
    //     .load(load_ir),
    //     .data_in(bus),
    //     .data_out(instruction)
    // );
    // program_counter u_pc (
    //     .clk(clk),
    //     .reset(reset),
    //     .load(load_pc),
    //     .inc(inc_pc),
    //     .data_in(bus),
    //     .data_out(pc_out)
    // );

    // memory_address_register u_mar_reg (
    //     .clk(clk),
    //     .reset(reset),
    //     .load(load_mar),
    //     .data_in(bus),
    //     .data_out(mar_out)
    // );

    // ram u_ram (
    //     .clk(clk),
    //     .we(we_ram),
    //     .oe(oe_ram),
    //     .address(mar_out),
    //     .data_in(bus),
    //     .data_out(ram_out)
    // );

    // control_unit u_control_unit (
    //     .clk(clk),
    //     .reset(reset),
    //     .instruction(ir_out),
    //     .load_a(load_a),
    //     .load_b(load_b),
    //     .load_out(load_out),
    //     .load_ir(load_ir),
    //     .inc_pc(inc_pc),
    //     .load_pc(load_pc),
    //     .load_mar(load_mar),
    //     .we_ram(we_ram),
    //     .oe_ram(oe_ram),
    //     // .alu_op(alu_op)
    // );

    // Bus logic (TBD): multiplexer / tri-state-style selectors between bus and internal outputs
    // TODO: Add bus arbitration logic

endmodule
