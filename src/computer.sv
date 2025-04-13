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

    // Control words are initialized to zero to avoid 'x' propagation in the system.
    control_word_t control_word = '{default: 0};

    // Microcode instruction format
    logic [OPCODE_WIDTH-1:0] opcode; 
    logic [OPERAND_WIDTH-1:0] operand; // Opcode and operand for instruction processing
    
    // Control signals for enabling/disabling the program counter
    logic pc_enable;
    
    logic [ADDR_WIDTH-1:0] counter_out, memory_address_out; // Outputs from the program counter and memory address register
    
    // Register outputs to simulate bus transceiver behavior
    logic [DATA_WIDTH-1:0] o_out, a_out, b_out, alu_out, ram_out;
    
    // Shared bus for data transfer among components
    logic [DATA_WIDTH-1:0] bus;
    
    // Control signals for loading data from the bus into registers
    logic load_o, load_a, load_b, load_ir, load_pc, load_flags, load_ram, load_mar;
    
    // Control signals for outputting data to the bus
    logic oe_a, oe_alu, oe_ir, oe_pc, oe_ram;

    // Control signal to indicate if the CPU should halt
    logic halt;

    logic [1:0] alu_op;
    
    // Instantiate the program counter with the specified address width
    program_counter u_program_counter (
        .clk(clk),
        .reset(reset),
        .enable(pc_enable),
        .load(load_pc),
        .counter_in(bus[3:0]),
        .counter_out(counter_out)
    );

    // Output register for holding the output value
    assign out_val = o_out;
    register_nbit #( .N(DATA_WIDTH) ) u_register_o (
        .clk(clk),
        .reset(reset),
        .load(load_o),
        .data_in(bus),
        .latched_data(o_out)
    );
    
    // Register A for holding one of the operands
    register_nbit #( .N(DATA_WIDTH) ) u_register_A (
        .clk(clk),
        .reset(reset),
        .load(load_a),
        .data_in(bus),
        .latched_data(a_out)
    );

    // Register B for holding another operand
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

    logic [2:0] flags_out;
    logic flag_zero;
    logic flag_carry;
    logic flag_negative;
    
    alu u_alu (
        .clk(clk),
        .reset(reset),
        .a_in(a_out),
        .b_in(b_out),
        .alu_op(alu_op),
        .latched_result(alu_out),
        .zero_flag(flag_zero),
        .carry_flag(flag_carry),
        .negative_flag(flag_negative)
    );
    
    register_nbit #( .N(3) ) u_register_flags (
        .clk(clk),
        .reset(reset),
        .load(load_flags),
        .data_in( {flag_negative, flag_carry, flag_zero} ),
        .latched_data(flags_out)
    );
    assign flag_zero_o = flags_out[0];
    assign flag_carry_o = flags_out[1];
    assign flag_negative_o = flags_out[2];

    // RAM module instantiation
    ram u_ram (
        .clk(clk),
        .we(load_ram),
        .address(memory_address_out),  
        .data_in(bus),
        .data_out(ram_out)
    );

    // Tri-state bus logic modeled using a priority multiplexer
    assign bus =    (oe_pc)     ? { {(DATA_WIDTH-ADDR_WIDTH){1'b0} }, counter_out } : // CO
                    (oe_ram)    ? ram_out :
                    (oe_ir)     ? { {(DATA_WIDTH-OPERAND_WIDTH){1'b0} }, operand } :
                    (oe_alu)    ? alu_out :
                    (oe_a)      ? a_out : 
                    { DATA_WIDTH {1'b0} };
    
    fsm_state_t current_state = S_RESET; // Current microstep in execution
    fsm_state_t next_state = S_RESET; // Next microstep to transition to
    microstep_t current_step; // Current microstep in execution
    microstep_t next_step; // Next microstep to transition to

    // Sequential logic for controlling the CPU's operation based on clock and reset signals
    always_ff @(posedge clk) begin 
        if (reset) begin 
            current_state <= S_RESET; // Reset to initial state
            current_step <= MS0; // Reset to initial step
        end else begin // Normal clocked operation
            current_state <= next_state; // Update to next step
            current_step <= next_step; // Update to next microstep  
        end
    end

    // Combinational logic to determine the next state and control word based on the current step
    always_comb begin 
        next_state = current_state; // Initialize next state to current state
        next_step = current_step; // Initialize next step to current step
        control_word = '{default: 0}; // Clear next control word

        case (current_state)
            S_RESET: begin
                next_state = S_FETCH_0; // Transition to fetch state
            end
            S_FETCH_0: begin
                control_word = '{default: 0, oe_pc: 1}; // Enable program counter output
                next_state = S_FETCH_1; // Move to next state
            end
            S_FETCH_1: begin
                control_word = '{default: 0, oe_pc: 1, load_mar: 1}; // Load memory address register
                next_state = S_DECODE_0; // Move to next state
            end
            S_DECODE_0: begin
                control_word = '{default: 0, oe_ram: 1}; // Enable RAM output
                next_state = S_DECODE_1; // Move to next step
            end
            S_DECODE_1: begin
                control_word = '{default: 0, oe_ram: 1, load_ir: 1, pc_enable: 1}; // Load instruction and enable PC
                next_state = S_WAIT; // Move to next step
            end
            S_WAIT: begin
                next_state = S_EXECUTE; // Critical delay to allow OPCODE latch
            end
            S_EXECUTE: begin
                control_word = microcode_rom[opcode][current_step]; // Fetch control word from microcode ROM
                if (control_word.halt) begin
                    next_state = S_HALT; 
                    next_step = MS0; 
                // end else if ( (control_word.check_zero && !flag_zero) ||
                //               (control_word.check_carry && !flag_carry) ) begin
                   
                //    // Skip loading PC with JMP address if conditions aren't met
                //    control_word = '{default:0};
                //    next_state = S_FETCH_0;
                //    next_step = MS0; 
                end else if (control_word.last_step) begin
                    next_state = S_FETCH_0; 
                    next_step = MS0; 
                end else begin
                    next_step = current_step + 1; // Increment microstep
                end
            end
            
            S_HALT: begin
                control_word = '{default: 0}; // Default control word
                next_state = S_HALT; // Remain in halt state
            end
            default: begin
                control_word = '{default: 0}; // Default control word
                next_state = S_HALT; // Transition to halt state on error
            end
        endcase
    end

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

    // Microcode ROM: 16 opcodes (4-bit program counter) and 8 microsteps per opcode
    // Ensure indexing does not exceed bounds of the ROM
    control_word_t microcode_rom [16][8];
    initial begin
        for (int i = 0; i < 16; i++) begin
            for (int s = 0; s < 8; s++) begin
                microcode_rom[i][s] = '{default: 0}; // Initialize each microstep to zero
            end
        end
        
        microcode_rom[NOP][MS0] = '{default: 0, last_step: 1}; // Load instruction register

        microcode_rom[LDA][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[LDA][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Prepare to load from RAM
        microcode_rom[LDA][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output
        microcode_rom[LDA][MS3] = '{default: 0, oe_ram: 1, load_a: 1, last_step: 1}; // Load value into register A
        
        microcode_rom[LDB][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[LDB][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Prepare to load from RAM
        microcode_rom[LDB][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output
        microcode_rom[LDB][MS3] = '{default: 0, oe_ram: 1, load_b: 1, last_step: 1}; // Load value into register B
        
        microcode_rom[ADD][MS0] = '{default: 0, oe_ir: 1};
        microcode_rom[ADD][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Load MAR with operand
        microcode_rom[ADD][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output        
        microcode_rom[ADD][MS3] = '{default: 0, oe_ram: 1, load_b: 1}; // Load value into register B
        microcode_rom[ADD][MS4] = '{default: 0, oe_alu: 1, load_flags: 1, alu_op: ALU_ADD}; // Add and output
        microcode_rom[ADD][MS5] = '{default: 0, oe_alu: 1, load_a: 1, last_step: 1}; // Load value into register A

        microcode_rom[SUB][MS0] = '{default: 0, oe_ir: 1};
        microcode_rom[SUB][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Load MAR with operand
        microcode_rom[SUB][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output        
        microcode_rom[SUB][MS3] = '{default: 0, oe_ram: 1, load_b: 1}; // Load value into register B
        microcode_rom[SUB][MS4] = '{default: 0, oe_alu: 1, load_flags: 1, alu_op: ALU_SUB}; // Add and output
        microcode_rom[SUB][MS5] = '{default: 0, oe_alu: 1, load_a: 1, last_step: 1}; // Load value into register A

        microcode_rom[AND][MS0] = '{default: 0, oe_ir: 1};
        microcode_rom[AND][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Load MAR with operand
        microcode_rom[AND][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output        
        microcode_rom[AND][MS3] = '{default: 0, oe_ram: 1, load_b: 1}; // Load value into register B
        microcode_rom[AND][MS4] = '{default: 0, oe_alu: 1, alu_op: ALU_AND}; // Add and output
        microcode_rom[AND][MS5] = '{default: 0, oe_alu: 1, load_a: 1, last_step: 1}; // Load value into register A

        microcode_rom[OR][MS0] = '{default: 0, oe_ir: 1};
        microcode_rom[OR][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Load MAR with operand
        microcode_rom[OR][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output        
        microcode_rom[OR][MS3] = '{default: 0, oe_ram: 1, load_b: 1}; // Load value into register B
        microcode_rom[OR][MS4] = '{default: 0, oe_alu: 1, alu_op: ALU_OR}; // Add and output
        microcode_rom[OR][MS5] = '{default: 0, oe_alu: 1, load_a: 1, last_step: 1}; // Load value into register A

        microcode_rom[STA][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[STA][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Prepare to load to RAM
        microcode_rom[STA][MS2] = '{default: 0, oe_a: 1}; // Enable A output
        microcode_rom[STA][MS3] = '{default: 0, oe_a: 1, load_ram: 1, last_step: 1}; // Load value into Mem
       
        microcode_rom[LDI][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[LDI][MS1] = '{default: 0, oe_ir: 1, load_a: 1, last_step: 1}; // Load A
        
        microcode_rom[JMP][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[JMP][MS1] = '{default: 0, oe_ir: 1, load_pc: 1, last_step: 1}; // Load program counter

        microcode_rom[JZ][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[JZ][MS1] = '{default: 0, oe_ir: 1, check_zero: 1, load_pc: 1, last_step: 1}; // Load program counter

        microcode_rom[JC][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[JC][MS1] = '{default: 0, oe_ir: 1, check_carry: 1, load_pc: 1, last_step: 1}; // Load program counter

        microcode_rom[OUTM][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[OUTM][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Prepare to load from RAM
        microcode_rom[OUTM][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output
        microcode_rom[OUTM][MS3] = '{default: 0, oe_ram: 1, load_o: 1, last_step: 1}; // Load value into register A
       
        microcode_rom[OUTA][MS0] = '{default: 0, oe_a: 1}; // Output register A
        microcode_rom[OUTA][MS1] = '{default: 0, oe_a: 1, load_o: 1, last_step: 1}; // 
        

        // Halt needs two cycles to stabilize
        microcode_rom[HLT][MS0] = '{default: 0}; // stabilization cycle
        microcode_rom[HLT][MS1] = '{default: 0, halt: 1, last_step: 1}; // halt
    end

endmodule
