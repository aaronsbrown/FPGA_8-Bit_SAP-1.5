typedef enum logic [3:0] {
        NOP = 4'b0000,
        LDA = 4'b0001,
        LDB = 4'b0010,
        ADD = 4'b0011,
        OUTA = 4'b1110,
        HLT = 4'b1111
} opcode_t;
    
typedef enum logic [3:0] {
    T0 = 4'b0000,
    T1 = 4'b0001,
    T2 = 4'b0010,
    T3 = 4'b0011,
    T4 = 4'b0100,
    T5 = 4'b0101,
    T6 = 4'b0110,
    T7 = 4'b0111,
    T8 = 4'b1000,
    T_RESET = 4'b1110,
    T_HLT = 4'b1111
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
    logic oe_alu;       //EO
    logic alu_sub;      //SU
    logic load_b;       //BI
    logic load_o;       //OI
    logic pc_enable;    //CE
    logic oe_pc;        //CO
    logic load_pc;      //J 
    logic load_flag;    //FI
    // logic oe_b;         //BO -- not in ben's 16bit contol word 
    
} control_word_t;

