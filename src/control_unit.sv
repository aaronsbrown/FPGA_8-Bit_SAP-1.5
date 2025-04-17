import arch_defs_pkg::*;

module control_unit (
    input   wire            clk,
    input   wire            reset,
    input   opcode_t        opcode,
    input   logic [2:0]     flags,
    output  control_word_t  control_word
);

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
    logic check_jump_condition = 1'b0; // Initialize jump condition check
    logic jump_condition_satisfied = 1'b0; // Initialize jump condition satisfied flag
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
                
                check_jump_condition = control_word.check_zero || control_word.check_carry || control_word.check_negative;
                jump_condition_satisfied = (control_word.check_zero && flags[0]) ||
                                                (control_word.check_carry && flags[1]) ||
                                                (control_word.check_negative && flags[2]);

                if (control_word.halt) begin
                    next_state = S_HALT; 
                    next_step = MS0; 
                end else if ( check_jump_condition && !jump_condition_satisfied) begin
                   
                   // Don't Jump! Suppress loading PC with new JMP address if conditions aren't met
                   control_word.load_pc = 1'b0;
                   next_state = S_FETCH_0;
                   next_step = MS0; 
                
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

    // ==================================================================================================
    // ======================================== MICROCODE ROM ===========================================
    //    Microcode ROM: 16 opcodes (4-bit program counter) and 8 microsteps per opcode
    control_word_t microcode_rom [16][8];
    initial begin
        for (int i = 0; i < 16; i++) begin
            for (int s = 0; s < 8; s++) begin
                microcode_rom[i][s] = '{default: 0}; // Initialize each microstep to zero
            end
        end
        
        // x00
        microcode_rom[NOP][MS0] = '{default: 0, last_step: 1}; // Load instruction register

        //x01
        microcode_rom[LDA][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[LDA][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Prepare to load from RAM
        microcode_rom[LDA][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output
        microcode_rom[LDA][MS3] = '{default: 0, oe_ram: 1, load_a: 1, load_flags: 1, load_sets_zn: 1, last_step: 1}; // Load value into register A
        
        //x02
        microcode_rom[LDB][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[LDB][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Prepare to load from RAM
        microcode_rom[LDB][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output
        microcode_rom[LDB][MS3] = '{default: 0, oe_ram: 1, load_b: 1, load_flags: 1, load_sets_zn: 1, last_step: 1}; // Load value into register B
        
        //x03
        microcode_rom[ADD][MS0] = '{default: 0, oe_ir: 1};
        microcode_rom[ADD][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Load MAR with operand
        microcode_rom[ADD][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output        
        microcode_rom[ADD][MS3] = '{default: 0, oe_ram: 1, load_b: 1}; // Load value into register B
        microcode_rom[ADD][MS4] = '{default: 0, oe_alu: 1, load_flags: 1, alu_op: ALU_ADD}; // Add and output
        microcode_rom[ADD][MS5] = '{default: 0, oe_alu: 1, load_a: 1, last_step: 1}; // Load value into register A

        //x04
        microcode_rom[SUB][MS0] = '{default: 0, oe_ir: 1};
        microcode_rom[SUB][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Load MAR with operand
        microcode_rom[SUB][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output        
        microcode_rom[SUB][MS3] = '{default: 0, oe_ram: 1, load_b: 1}; // Load value into register B
        microcode_rom[SUB][MS4] = '{default: 0, oe_alu: 1, load_flags: 1, alu_op: ALU_SUB}; // Add and output
        microcode_rom[SUB][MS5] = '{default: 0, oe_alu: 1, load_a: 1, last_step: 1}; // Load value into register A

        //x05
        microcode_rom[AND][MS0] = '{default: 0, oe_ir: 1};
        microcode_rom[AND][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Load MAR with operand
        microcode_rom[AND][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output        
        microcode_rom[AND][MS3] = '{default: 0, oe_ram: 1, load_b: 1}; // Load value into register B
        microcode_rom[AND][MS4] = '{default: 0, oe_alu: 1, load_flags: 1, alu_op: ALU_AND}; // Add and output
        microcode_rom[AND][MS5] = '{default: 0, oe_alu: 1, load_a: 1, last_step: 1}; // Load value into register A

        //x06
        microcode_rom[OR][MS0] = '{default: 0, oe_ir: 1};
        microcode_rom[OR][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Load MAR with operand
        microcode_rom[OR][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output        
        microcode_rom[OR][MS3] = '{default: 0, oe_ram: 1, load_b: 1}; // Load value into register B
        microcode_rom[OR][MS4] = '{default: 0, oe_alu: 1, load_flags: 1, alu_op: ALU_OR}; // Add and output
        microcode_rom[OR][MS5] = '{default: 0, oe_alu: 1, load_a: 1, last_step: 1}; // Load value into register A

        //x07
        microcode_rom[STA][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[STA][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Prepare to load to RAM
        microcode_rom[STA][MS2] = '{default: 0, oe_a: 1}; // Enable A output
        microcode_rom[STA][MS3] = '{default: 0, oe_a: 1, load_ram: 1, last_step: 1}; // Load value into Mem
       
        //x08
        microcode_rom[LDI][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[LDI][MS1] = '{default: 0, oe_ir: 1, load_a: 1, load_flags: 1, load_sets_zn: 1, last_step: 1}; // Load A
        
        //x09
        microcode_rom[JMP][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[JMP][MS1] = '{default: 0, oe_ir: 1, load_pc: 1, last_step: 1}; // Load program counter

        //x0A
        microcode_rom[JC][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[JC][MS1] = '{default: 0, oe_ir: 1, check_carry: 1, load_pc: 1, last_step: 1}; // Load program counter

        //x0B
        microcode_rom[JZ][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[JZ][MS1] = '{default: 0, oe_ir: 1, check_zero: 1, load_pc: 1, last_step: 1}; // Load program counter

        //x0C
        microcode_rom[JN][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[JN][MS1] = '{default: 0, oe_ir: 1, check_negative: 1, load_pc: 1, last_step: 1}; // Load program counter

        //x0D
        microcode_rom[OUTM][MS0] = '{default: 0, oe_ir: 1}; // Load instruction register
        microcode_rom[OUTM][MS1] = '{default: 0, oe_ir: 1, load_mar: 1}; // Prepare to load from RAM
        microcode_rom[OUTM][MS2] = '{default: 0, oe_ram: 1}; // Enable RAM output
        microcode_rom[OUTM][MS3] = '{default: 0, oe_ram: 1, load_o: 1, last_step: 1}; // Load value into register A
       
        //x0E
        microcode_rom[OUTA][MS0] = '{default: 0, oe_a: 1}; // Output register A
        microcode_rom[OUTA][MS1] = '{default: 0, oe_a: 1, load_o: 1, last_step: 1}; // 
        
        //x0F
        // Halt needs two cycles to stabilize
        microcode_rom[HLT][MS0] = '{default: 0}; // stabilization cycle
        microcode_rom[HLT][MS1] = '{default: 0, halt: 1, last_step: 1}; // halt
    end

endmodule