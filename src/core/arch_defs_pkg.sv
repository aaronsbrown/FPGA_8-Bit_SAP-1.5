package arch_defs_pkg;

    parameter int DATA_WIDTH = 8;
    parameter int ADDR_WIDTH = 4;

    parameter int RAM_DEPTH = (1 << ADDR_WIDTH);
    parameter int OPCODE_WIDTH = 4;
    parameter int OPERAND_WIDTH = DATA_WIDTH - OPCODE_WIDTH;

    typedef enum logic [OPCODE_WIDTH-1:0] {
        NOP =   4'b0000,
        LDA =   4'b0001, // tested
        LDB =   4'b0010, // tested
        ADD =   4'b0011,
        SUB =   4'b0100,
        AND =   4'b0101,
        OR  =   4'b0110,
        STA =   4'b0111,
        LDI =   4'b1000, // tested
        JMP =   4'b1001,
        JC  =   4'b1010, // need flag reg
        JZ  =   4'b1011, // need flag reg
        OUTM =  4'b1101, 
        OUTA =  4'b1110,
        HLT =   4'b1111
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
        logic halt;         //#19      
        logic last_step;    //#18     
        logic pc_enable;    //#17       
        logic load_pc;      //#16      
        logic oe_pc;        //#15      
        logic load_ir;      //#14      
        logic oe_ir;        //#13      
        logic load_mar;     //#12      
        logic load_ram;     //#11      
        logic oe_ram;       //#10      
        logic [1:0] alu_op; //#9      
        logic oe_alu;       //#8      
        logic check_zero;   //#7      
        logic check_carry;  //#6      
        logic load_a;       //#5      
        logic oe_a;         //#4      
        logic load_b;       //#3      
        logic oe_b;         //#2      
        logic load_o;       //#1      

    } control_word_t;

endpackage : arch_defs_pkg