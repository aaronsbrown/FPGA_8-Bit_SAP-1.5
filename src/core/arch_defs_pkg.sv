package arch_defs_pkg;

    parameter int DATA_WIDTH = 8;
    parameter int ADDR_WIDTH = 4;

    parameter int RAM_DEPTH = (1 << ADDR_WIDTH);
    parameter int OPCODE_WIDTH = 4;
    parameter int OPERAND_WIDTH = DATA_WIDTH - OPCODE_WIDTH;

    typedef enum logic [OPCODE_WIDTH-1:0] {
        NOP =   4'b0000, // tested
        LDA =   4'b0001, // tested
        LDB =   4'b0010, // tested
        ADD =   4'b0011, // tested
        SUB =   4'b0100, // tested
        AND =   4'b0101, // tested
        OR  =   4'b0110, // tested
        STA =   4'b0111, // tested
        LDI =   4'b1000, // tested
        JMP =   4'b1001, // tested
        JC  =   4'b1010, // tested
        JZ  =   4'b1011, // tested
        JN  =   4'b1100, // tested
        OUTM =  4'b1101, // tested
        OUTA =  4'b1110, // tested
        HLT =   4'b1111  // tested
    } opcode_t;
        
    typedef enum logic [1:0] {
        ALU_ADD = 2'b00,
        ALU_SUB = 2'b01,
        ALU_AND = 2'b10,
        ALU_OR  = 2'b11
    } alu_op_t;

    typedef enum logic [2:0] {
        S_RESET,
        S_FETCH_0,
        S_FETCH_1,
        S_DECODE_0,
        S_DECODE_1,
        S_EXECUTE,
        S_WAIT,
        S_HALT
    } fsm_state_t;

    typedef enum logic [3:0] {
        MS0, MS1, MS2, MS3, MS4, MS5, MS6, MS7
    } microstep_t;

    typedef struct packed {
        opcode_t opcode;
        logic [OPERAND_WIDTH-1:0] operand;
    } instruction_t;

    typedef struct packed {
        logic halt;               
        logic last_step;         
        logic pc_enable;           
        logic load_pc;            
        logic oe_pc;              
        logic load_ir;            
        logic oe_ir;              
        logic load_mar;           
        logic load_ram;           
        logic oe_ram;             
        logic [1:0] alu_op;       
        logic oe_alu;             
        logic load_flags;   
        logic load_sets_zn; 
        logic check_zero;         
        logic check_carry;  
        logic check_negative;  
        logic load_a;             
        logic oe_a;               
        logic load_b;             
        logic oe_b;               
        logic load_o;             

    } control_word_t;

endpackage : arch_defs_pkg