module computer (
    input wire clk,
    input wire reset, 
    output wire [7:0] out_val
);
    
    
    logic [2:0] microstep;
    localparam  T0_FETCH = 3'b000,
                T1_DECODE = 3'b001,
                T2_EXECUTE = 3'b010,
                T3_WAIT = 3'b011;
    
    // Shared bus for data transfer
    logic [7:0] bus;
    
    // Simple Registers & control signals
    logic pc_enable, pc_load;
    logic [7:0] a_out, b_out, ir_out, counter_out, temp_out, ram_out;
    logic [3:0] opcode, operand;
    logic load_a, load_b, load_ir, load_pc, load_temp, ram_we;
    logic oe_a, oe_b, oe_ir, oe_pc, oe_temp, oe_ram;
    
    program_counter #( .ADDR_WIDTH(4) ) u_program_counter (
        .clk(clk),
        .reset(reset),
        .enable(pc_enable),
        .load(pc_load),
        .counter_in(bus),
        .counter_out(counter_out)
    );

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
        .oe(oe_ram),
        .address(operand),  // TODO replace this with MAR
        .data_in(bus),
        .data_out(ram_out)
    );

    assign bus =    (oe_temp)   ? temp_out :
                    (oe_pc)     ? counter_out : //CO
                    (oe_ram)    ? ram_out :
                    (oe_ir)     ? operand :
                    (oe_a)      ? a_out : 
                    (oe_b)      ? b_out : 
                    8'b0;
    
    assign out_val = bus;
    
    always @(posedge clk) begin
        if (reset) begin
            microstep <= T0_FETCH;
            
            load_a <= 0;
            load_b <= 0;
            load_ir <= 0;
            load_temp <= 0;
            
            oe_a <= 0;
            oe_b <= 0;
            oe_ir <= 0;
            oe_temp <= 0;

        end else begin
            case (microstep)
                
                T0_FETCH: begin
                    oe_temp <= 1;
                    load_ir <= 1;
                    microstep <= T1_DECODE;
                end
                
                T1_DECODE: begin
                    
                    oe_temp <= 0;
                    load_ir <= 0;

                    oe_ir <= 1;
                    case (opcode)
                        4'b0001: begin
                            load_a <= 1;
                            microstep <= T2_EXECUTE;
                        end
                    endcase
                    
                end
                
                T2_EXECUTE: begin 
                    load_a <= 0;
                    oe_a <= 1;
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

  

    // memory_address_register u_mar_reg (
    //     .clk(clk),
    //     .reset(reset),
    //     .load(load_mar),
    //     .data_in(bus),
    //     .data_out(mar_out)
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
