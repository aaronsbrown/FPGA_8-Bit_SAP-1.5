typedef enum logic [3:0] {
        NOP =   4'b0000,
        LDA =   4'b0001,
        LDB =   4'b0010,
        ADD =   4'b0011,
        SUB =   4'b0100,
        AND =   4'b0101,
        OR  =   4'b0110,
        STA =   4'b0111,
        LDI =   4'b1000,
        JMP =   4'b1001,
        JC  =   4'b1010,
        JZ  =   4'b1011,
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
    logic [3:0] operand;
} instruction_t;

typedef struct packed {
    logic halt;         //HLT  
    logic load_mar;     //MI
    logic load_ram;     //RI
    logic oe_ram;       //RO
    logic load_ir;      //II
    logic oe_ir;        //IO
    logic load_a;       //AI
    logic oe_a;         //AO
    logic oe_b;         //BO
    logic oe_alu;       //EO
    logic [1:0] alu_op;
    logic load_b;       //BI
    logic load_o;       //OI
    logic pc_enable;    //CE
    logic oe_pc;        //CO
    logic load_pc;      //J 
    logic load_flag;    //FI
    logic last_step;   //LS
    logic check_zero;
    logic check_carry;
    
    
} control_word_t;

