`include "include/microarch_defs.sv"

// This module implements a simple microcoded CPU architecture. It includes a program counter, registers, 
// a RAM interface, and a microcode ROM to control the CPU's operations based on opcodes and microsteps.

module computer (
    input wire clk,
    input wire reset, 
    output wire [7:0] out_val
);

    // Control words are initialized to zero to avoid 'x' propagation in the system.
    control_word_t control_word = '{default: 0}; 
    control_word_t next_control_word = '{default: 0};

    // Microcode instruction format
    logic [3:0] opcode, operand; // Opcode and operand for instruction processing
    
    // Control signals for enabling/disabling the program counter
    logic pc_enable;
    
    logic [3:0] counter_out, memory_address_out; // Outputs from the program counter and memory address register
    
    // Register outputs to simulate bus transceiver behavior
    logic [7:0] a_out, b_out, ir_out, temp_out, ram_out;
    
    // Shared bus for data transfer among components
    logic [7:0] bus;
    
    // Control signals for loading data from the bus into registers
    logic load_a, load_b, load_ir, load_pc, load_temp, load_ram, load_mar;
    
    // Control signals for outputting data to the bus
    logic oe_a, oe_b, oe_ir, oe_pc, oe_temp, oe_ram;

    // Control signal to indicate if the CPU should halt
    logic halt;
    
    // Instantiate the program counter with the specified address width
    program_counter #( .ADDR_WIDTH(4) ) u_program_counter (
        .clk(clk),
        .reset(reset),
        .enable(pc_enable),
        .load(load_pc),
        .counter_in(bus[3:0]),
        .counter_out(counter_out)
    );

    // Temporary register for holding intermediate values
    register_nbit #( .N(8) ) u_register_temp (
        .clk(clk),
        .reset(reset),
        .load(load_temp),
        .data_in(bus),
        .latched_data(temp_out)
    );

    // Register A for holding one of the operands
    register_nbit #( .N(8) ) u_register_A (
        .clk(clk),
        .reset(reset),
        .load(load_a),
        .data_in(bus),
        .latched_data(a_out)
    );

    // Register B for holding another operand
    register_nbit #( .N(8) ) u_register_B (
        .clk(clk),
        .reset(reset),
        .load(load_b),
        .data_in(bus),
        .latched_data(b_out)
    );

    // Memory address register for RAM operations
    register_nbit #( .N(4) ) u_register_memory_address (
        .clk(clk),
        .reset(reset),
        .load(load_mar),
        .data_in(bus[3:0]),
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
    
    // RAM module instantiation
    ram u_ram (
        .clk(clk),
        .we(load_ram),
        .oe(oe_ram),
        .address(memory_address_out),  
        .data_in(bus),
        .data_out(ram_out)
    );

    // Tri-state bus logic modeled using a priority multiplexer
    assign bus =    (oe_temp)   ? temp_out :
                    (oe_pc)     ? counter_out : // CO
                    (oe_ram)    ? ram_out :
                    (oe_ir)     ? operand :
                    (oe_a)      ? a_out : 
                    (oe_b)      ? b_out : 
                    8'b0;
    
    assign out_val = bus; // Output the value on the bus
    
    microstep_t current_step = T_RESET; // Current microstep in execution
    microstep_t next_step = T_RESET; // Next microstep to transition to

    // Sequential logic for controlling the CPU's operation based on clock and reset signals
    always_ff @(posedge clk or posedge reset) begin // ADD posedge reset
        if (reset) begin // ASYNC check
            current_step <= T_RESET; // Reset to initial state
            control_word <= '{default: 0}; // Clear control word
        end else begin // Normal clocked operation
            // Handle halt logic; may require adjustment for synchronous/asynchronous intent
            if (halt) begin
                current_step <= T_HLT; // Transition to halt state
                control_word <= '{default: 0}; // Clear control word
            end else begin
                current_step <= next_step; // Update to next step
                control_word <= next_control_word; // Update control word
            end
        end
    end

    // Combinational logic to determine the next state and control word based on the current step
    always_comb begin 
        next_step = current_step; // Initialize next step to current step
        next_control_word = '{default: 0}; // Clear next control word

        case (current_step)
            T_RESET: begin
                next_step = T0; // Transition to first microstep
            end
            T0: begin
                next_control_word = '{default: 0, oe_pc: 1}; // Enable program counter output
                next_step = T1; // Move to next step
            end
            T1: begin
                next_control_word = '{default: 0, oe_pc: 1, load_mar: 1}; // Load memory address register
                next_step = T2; // Move to next step
            end
            T2: begin
                next_control_word = '{default: 0, oe_ram: 1}; // Enable RAM output
                next_step = T3; // Move to next step
            end
            T3: begin
                next_control_word = '{default: 0, oe_ram: 1, load_ir: 1, pc_enable: 1}; // Load instruction and enable PC
                next_step = T4; // Move to next step
            end
            // Microsteps for executing instructions
            T4: begin
                next_control_word = microcode_rom[opcode][T4]; // Fetch control word from microcode ROM
                next_step = T5; // Move to next step
            end
            T5: begin
                next_control_word = microcode_rom[opcode][T5]; // Fetch control word from microcode ROM
                next_step = T6; // Move to next step
            end
            T6: begin
                next_control_word = microcode_rom[opcode][T6]; // Fetch control word from microcode ROM
                next_step = T7; // Move to next step
            end
            T7: begin
                next_control_word = microcode_rom[opcode][T7]; // Fetch control word from microcode ROM
                next_step = T8; // Move to next step
            end
            T8: begin
                next_control_word = microcode_rom[opcode][T8]; // Fetch control word from microcode ROM
                next_step = T0; // Loop back to the start
            end
            T_HLT: begin
                next_step = T_HLT; // Remain in halt state
            end
            default: begin
                next_control_word = '{default: 0}; // Default control word
                next_step = T_HLT; // Transition to halt state on error
            end
        endcase
    end

    // Assign control signals from the control word
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

    // Microcode ROM: 16 opcodes (4-bit program counter) and 8 microsteps per opcode
    // Ensure indexing does not exceed bounds of the ROM
    control_word_t microcode_rom [16][8];
    initial begin
        for (int i = 0; i < 16; i++) begin
            for (int s = 0; s < 8; s++) begin
                microcode_rom[i][s] = '{default: 0}; // Initialize each microstep to zero
            end
        end
        
        // These assignments are not strictly necessary due to default initialization, 
        // but they improve clarity by explicitly stating the intended behavior.
        microcode_rom[NOP][T4] = '{default: 0}; 
        microcode_rom[NOP][T5] = '{default: 0}; 
        microcode_rom[NOP][T6] = '{default: 0}; 
        microcode_rom[NOP][T7] = '{default: 0}; 
        
        microcode_rom[LDA][T4] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[LDA][T5] = '{default: 0, oe_ir: 1, load_mar: 1}; // Prepare to load from RAM
        microcode_rom[LDA][T6] = '{default: 0, oe_ram: 1}; // Enable RAM output
        microcode_rom[LDA][T7] = '{default: 0, oe_ram: 1, load_a: 1}; // Load value into register A
        microcode_rom[LDA][T8] = '{default: 0}; // End of LDA instruction

        microcode_rom[HLT][T4] = '{default: 0, halt: 1}; // Set halt signal
        microcode_rom[HLT][T5] = '{default: 0, halt: 1}; // Maintain halt signal
        microcode_rom[HLT][T6] = '{default: 0, halt: 1}; // Maintain halt signal
        microcode_rom[HLT][T7] = '{default: 0, halt: 1}; // Maintain halt signal
    end

    // TODO: output_register u_out_reg (to be implemented in future)
    
    // TODO: alu u_alu (to be implemented in future)
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

endmodule
