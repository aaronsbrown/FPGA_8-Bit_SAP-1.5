module computer (
    input wire clk,
    input wire reset, 
    output wire [7:0] out_val
);
    
    
    reg [2:0] microstep;
    localparam  T0_FETCH = 3'b000,
                T1_DECODE = 3'b001,
                T2_EXECUTE = 3'b010,
                T3_WAIT = 3'b011;
    
    // Shared bus for data transfer
    wire [7:0] bus;
    
    // Simple Registers & control signals
    wire [7:0] a_out, b_out, ir_out, temp_out, ram_out;
    wire [3:0] opcode, operand;
    reg load_a, load_b, load_ir, load_temp, ram_we;
    reg enable_a, enable_b, enable_ir, enable_temp, ram_oe;
    
    

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

    
    register_instruction u_register_instr (
        .clk(clk),
        .reset(reset),
        .load(load_ir),
        .data_in(bus),
        .opcode(opcode),
        .operand(operand)
    );
    
    ram u_ram (
        .clk(clk),
        .we(ram_we),
        .oe(ram_oe),
        .address(operand),  // TODO replace this with MAR
        .data_in(bus),
        .data_out(ram_out)
    );

    assign bus =    (enable_temp)   ? temp_out :
                    (ram_oe)        ? ram_out :
                    (enable_ir)     ? operand :
                    (enable_a)      ? a_out : 
                    (enable_b)      ? b_out : 
                    8'b0;
    
    assign out_val = bus;
    
    always @(posedge clk) begin
        if (reset) begin
            microstep <= T0_FETCH;
            
            load_a <= 0;
            load_b <= 0;
            load_ir <= 0;
            load_temp <= 0;
            
            enable_a <= 0;
            enable_b <= 0;
            enable_ir <= 0;
            enable_temp <= 0;

        end else begin
            case (microstep)
                
                T0_FETCH: begin
                    enable_temp <= 1;
                    load_ir <= 1;
                    microstep <= T1_DECODE;
                end
                
                T1_DECODE: begin
                    
                    enable_temp <= 0;
                    load_ir <= 0;

                    enable_ir <= 1;
                    case (opcode)
                        4'b0001: begin
                            load_a <= 1;
                            microstep <= T2_EXECUTE;
                        end
                    endcase
                    
                end
                
                T2_EXECUTE: begin 
                    load_a <= 0;
                    enable_a <= 1;
                    microstep <= T3_WAIT;
                end
                
                T3_WAIT: begin 
                   // noop
                end
                
                default: microstep <= T0_FETCH;
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


endmodule
