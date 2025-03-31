`include "include/microarch_defs.sv"

module computer (
    input wire clk,
    input wire reset, 
    output wire [7:0] out_val
);
    control_word_t control_word = '{default: 0};
    control_word_t next_control_word = '{default: 0};


    // Microcode
    logic [3:0] opcode, operand;
    
    // Control signals => program counter
    logic pc_enable;
    
    logic [3:0] counter_out, memory_address_out;
    
    // Register output storage (simulates bus-transciever )
    logic [7:0] a_out, b_out, ir_out, temp_out, ram_out;
    
    // Shared bus for data transfer
    logic [7:0] bus;
    
    // Control signals => load from bus
    logic load_a, load_b, load_ir, load_pc, load_temp, load_ram, load_mar;
    
    // Control signals => output to bus
    logic oe_a, oe_b, oe_ir, oe_pc, oe_temp, oe_ram;

    // Control signals => computer
    logic halt;
    
    program_counter #( .ADDR_WIDTH(4) ) u_program_counter (
        .clk(clk),
        .reset(reset),
        .enable(pc_enable),
        .load(load_pc),
        .counter_in(bus[3:0]),
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

    register_nbit #( .N(4) ) u_register_memory_address (
        .clk(clk),
        .reset(reset),
        .load(load_mar),
        .data_in(bus[3:0]),
        .latched_data(memory_address_out)
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
        .we(load_ram),
        .oe(oe_ram),
        .address(memory_address_out),  
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
    
    microstep_t current_step = T_RESET;
    microstep_t next_step = T_RESET;

    always_ff @(posedge clk or posedge reset) begin // ADD posedge reset
        if (reset) begin // ASYNC check
            current_step <= T_RESET;
            control_word <= '{default: 0};
        end else begin // Normal clocked operation
            // Halt logic might need adjustment depending on sync/async intent
            if (halt) begin
                current_step <= T_HLT;
                control_word <= '{default: 0};
            end else begin
                current_step <= next_step;
                control_word <= next_control_word;
            end
        end
    end

    always_comb begin 
        
        next_step = current_step;
        next_control_word = '{default: 0};

        case (current_step)
            T_RESET: begin
                next_step = T0;
            end
            T0: begin
                next_control_word = '{default: 0, oe_pc: 1};
                next_step = T1; 
            end
            T1: begin
                next_control_word = '{default: 0, oe_pc: 1, load_mar: 1};
                next_step = T2;
            end
            T2: begin
                next_control_word = '{default: 0, oe_ram: 1};
                next_step = T3;
            end
            T3: begin
                next_control_word = '{default: 0, oe_ram: 1, load_ir: 1, pc_enable: 1};
                next_step = T4;
            end
            T4: begin
                next_control_word = microcode_rom[opcode][T4];
                next_step = T5;
            end
            T5: begin
                next_control_word = microcode_rom[opcode][T5];
                next_step = T6;
            end
            T6: begin
                next_control_word = microcode_rom[opcode][T6];
                next_step = T7;
            end
            T7: begin
                next_control_word = microcode_rom[opcode][T7];
                next_step = T8;
            end
            T8: begin
                next_control_word = microcode_rom[opcode][T8];
                next_step = T0;
            end
            T_HLT: begin
                next_step = T_HLT; //infinite loop
            end
            default: begin
                next_control_word = '{default: 0};
                next_step = T_HLT;
            end
        endcase
    end

    assign load_a = control_word.load_a;
    assign load_b = control_word.load_b;
    assign load_ir = control_word.load_ir;
    assign load_pc = control_word.load_pc;
    assign load_mar = control_word.load_mar;
    assign load_ram = control_word.load_ram;
    assign load_temp = control_word.load_temp;
    assign oe_a = control_word.oe_a;
    assign oe_b = control_word.oe_b;        
    assign oe_ir = control_word.oe_ir;
    assign oe_pc = control_word.oe_pc;
    assign oe_ram = control_word.oe_ram;
    assign oe_temp = control_word.oe_temp;
    assign pc_enable = control_word.pc_enable; 
    assign halt = control_word.halt; 


    // Microcode ROM: 16 opcodes (4bit program counter)
    // 8 microsteps possible
    control_word_t microcode_rom [16][8];
    initial begin

        for (int i = 0; i < 16; i++) begin
            for (int s = 0; s < 8; s++) begin
            microcode_rom[i][s] = '{default: 0};
            end
        end
        
        microcode_rom[NOP][T4] = '{default: 0};
        microcode_rom[NOP][T5] = '{default: 0};
        microcode_rom[NOP][T6] = '{default: 0};
        microcode_rom[NOP][T7] = '{default: 0};
        
        microcode_rom[LDA][T4] = '{default: 0, oe_ir: 1};
        microcode_rom[LDA][T5] = '{default: 0, oe_ir: 1, load_mar: 1};
        microcode_rom[LDA][T6] = '{default: 0, oe_ram: 1};
        microcode_rom[LDA][T7] = '{default: 0, oe_ram: 1, load_a: 1};
        microcode_rom[LDA][T8] = '{default: 0};

        microcode_rom[HLT][T4] = '{default: 0, halt: 1};
        microcode_rom[HLT][T5] = '{default: 0, halt: 1};
        microcode_rom[HLT][T6] = '{default: 0, halt: 1};
        microcode_rom[HLT][T7] = '{default: 0, halt: 1};
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
