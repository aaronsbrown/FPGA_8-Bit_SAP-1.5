import arch_defs_pkg::*;

// This module implements a simple microcoded CPU architecture. It includes a program counter, registers, 
// a RAM interface, and a microcode ROM to control the CPU's operations based on opcodes and microsteps.

module computer (
    input wire  clk,
    input wire  reset, 
    output wire [DATA_WIDTH-1:0] out_val,
    output wire flag_zero_o,
    output wire flag_carry_o,
    output wire flag_negative_o
);
    
    // ===================== MICROCODE STRUCTURAL DEFINITION ==============
    // ====================================================================
    logic [OPCODE_WIDTH-1:0] opcode; 
    logic [OPERAND_WIDTH-1:0] operand; 
    
    
    // ===================== ALU OPERATIONS ==============
    // ===================================================
    logic [1:0] alu_op;

    
    // ================= CONTROL SIGNALS =================
    // ===================================================
    // Control word is initialized to zero to avoid 'x' propagation in the system.
    control_word_t control_word = '{default: 0};

    logic halt;
    logic pc_enable;

    // Control signals for loading data from the bus into registers
    logic load_o, load_a, load_b, load_ir, load_pc, load_flags, load_sets_zn, load_ram, load_mar;
    
    // Control signals for outputting data to the bus
    logic oe_a, oe_alu, oe_ir, oe_pc, oe_ram;

    
    // ================= BUS INTERFACE and 'bus staging' registers ==================
    // ==============================================================================
    logic [DATA_WIDTH-1:0] bus;
    logic [DATA_WIDTH-1:0] o_out, a_out, b_out, alu_out, ram_out;
    logic [DATA_WIDTH-1:0] counter_out, memory_address_out;
    
    // Tri-state bus logic modeled using a priority multiplexer
    assign bus =    (oe_pc)     ? { {(DATA_WIDTH-ADDR_WIDTH){1'b0} }, counter_out } :
                    (oe_ram)    ? ram_out :
                    (oe_ir)     ? { {(DATA_WIDTH-OPERAND_WIDTH){1'b0} }, operand } :
                    (oe_alu)    ? alu_out :
                    (oe_a)      ? a_out : 
                    { DATA_WIDTH {1'b0} };


    // ================ REGISTER DECLARATIONS ===========
    // ==================================================
    program_counter u_program_counter (
        .clk(clk),
        .reset(reset),
        .enable(pc_enable),
        .load(load_pc),
        .counter_in(bus[ADDR_WIDTH-1:0]),
        .counter_out(counter_out)
    );

    register_nbit #( .N(DATA_WIDTH) ) u_register_OUT (
        .clk(clk),
        .reset(reset),
        .load(load_o),
        .data_in(bus),
        .latched_data(o_out)
    );
    assign out_val = o_out;    
    
    register_nbit #( .N(DATA_WIDTH) ) u_register_A (
        .clk(clk),
        .reset(reset),
        .load(load_a),
        .data_in(bus),
        .latched_data(a_out)
    );

    register_nbit #( .N(DATA_WIDTH) ) u_register_B (
        .clk(clk),
        .reset(reset),
        .load(load_b),
        .data_in(bus),
        .latched_data(b_out)
    );

    // Memory address register for RAM operations
    register_nbit #( .N(ADDR_WIDTH) ) u_register_memory_address (
        .clk(clk),
        .reset(reset),
        .load(load_mar),
        .data_in(bus[ADDR_WIDTH-1:0]),
        .latched_data(memory_address_out)
    );

    // Instruction register to hold the current instruction
    register_instruction u_register_instr (
        .clk(clk),
        .reset(reset),
        .load(load_ir),
        .data_in(bus),
        .opcode(opcode),
        .operand(operand)
    );

    // IMPORTANT: Synthesis Optimization Note (Yosys/synth_ice40)
    // Added (* keep *) attribute below because default synthesis optimization
    // was observed to incorrectly alter or remove the flags register logic
    // The (* keep *) prevents Yosys from over-optimizing
    // this critical state-holding element, ensuring correct hardware behavior
    // across different program complexities. The root cause appears to be
    // an optimization that misinterprets the usage scope of the flags when
    // conditional jumps aren't the final instructions using them.
    (* keep *) logic [FLAG_COUNT-1:0] flags_out;
    
    // Flags register to hold the status flags
    // Z: Zero flag, C: Carry flag, N: Negative flag
    register_nbit #( .N(FLAG_COUNT) ) u_register_flags (
        .clk(clk),
        .reset(reset),
        .load(load_flags),
        .data_in( {N_in, C_in, Z_in} ),
        .latched_data(flags_out)
    );
    assign flag_zero_o = flags_out[0];
    assign flag_carry_o = flags_out[1];
    assign flag_negative_o = flags_out[2];

    

    // ================ MAIN COMPONENTS: ALU, CONTROL UNIT, RAM ================
    // =========================================================================
    control_unit u_control_unit (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .flags(flags_out),
        .control_word(control_word)
    );
    
    // Assign control signals from the control word
    assign load_o = control_word.load_o;
    assign load_a = control_word.load_a;
    assign load_b = control_word.load_b;
    assign load_ir = control_word.load_ir;
    assign load_pc = control_word.load_pc;
    assign load_mar = control_word.load_mar;
    assign load_ram = control_word.load_ram;
    assign oe_a = control_word.oe_a;
    assign oe_ir = control_word.oe_ir;
    assign oe_pc = control_word.oe_pc;
    assign oe_alu = control_word.oe_alu;
    assign oe_ram = control_word.oe_ram;
    assign alu_op = control_word.alu_op;
    assign pc_enable = control_word.pc_enable; 
    assign halt = control_word.halt; 
    assign load_flags = control_word.load_flags;
    assign load_sets_zn = control_word.load_sets_zn; 

    alu u_alu (
        .clk(clk),
        .reset(reset),
        .a_in(a_out),
        .b_in(b_out),
        .alu_op(alu_op),
        .latched_result(alu_out),
        .zero_flag(flag_alu_zero),
        .carry_flag(flag_alu_carry),
        .negative_flag(flag_alu_negative)
    );

    ram u_ram (
        .clk(clk),
        .we(load_ram),
        .address(memory_address_out),  
        .data_in(bus),
        .data_out(ram_out)
    );
    

    // ================================ FLAG LOGIC ===============================
    // ===========================================================================
    logic flag_alu_zero;
    logic flag_alu_carry;
    logic flag_alu_negative;

    // TODO this is bugged, opcode test is erroneous
    // Determine if the LOAD operation resulted in zero or negative
    logic load_data_is_zero, load_data_is_negative;
    assign load_data_is_zero = (opcode == (LDI || LDA || LDB ) ) ? 
                                          ( load_a && ( operand == { OPERAND_WIDTH{1'b0} }) ) :
                                          ( ( load_a || load_b ) && ( bus == { DATA_WIDTH{1'b0} }) );
    
    assign load_data_is_negative = (opcode == (LDI || LDA || LDB ) ) ? 
                                              ( load_a && operand[OPERAND_WIDTH - 1] ) :
                                              ( ( load_a || load_b ) && ( bus[DATA_WIDTH - 1] ) );
    
    // Determine if flags should be set based on ALU op or LDI/LDA/LDB
    logic Z_in, N_in, C_in;
    always_comb begin
        Z_in = flag_alu_zero;
        N_in = flag_alu_negative;
        C_in = flag_alu_carry;
        if (load_sets_zn) begin
            Z_in = load_data_is_zero;
            N_in = load_data_is_negative;
            C_in = 1'b0; // Carry flag is not set for LOAD operations
        end
    end
endmodule
