`ifndef __PIPELINE_SVH__
`define __PIPELINE_SVH__
`include "common.svh"
typedef struct packed {
    logic INT,ADEL,ADES,SYS,BP,RI,OV,wen,EXL,eret;
    logic [4:0] regw;
} EXP_sig;

typedef enum i5 { 
    INT=5'b00000,
    ADEL=5'b00100,
    ADES=5'b00101,
    SYS=5'b01000,
    BP=5'b01001,
    RI=5'b01010,
    OV=5'b01100
} ExcCode_t;

typedef struct packed {
    i32 badvaddr,count,compare,EPC,status,cause;
} CP0_t;
typedef struct packed {
    i32 pc;
} F_type;
typedef struct packed {
    i32 pc,imp;
    EXP_sig exp;
} D_type;
typedef struct packed {
    i6 OP,FN;
    i5 regw,sa;
    i32 valA,valB,valC,pc;
    logic hi_w,lo_w,t;
    EXP_sig exp;
} E_type;
typedef struct packed {
    i6 OP;
    i32 valA,valB,pc;
    logic rm,wm,hi_w,lo_w,t;
    i5 regw;
    EXP_sig exp;
} M_type;
typedef struct packed {
    i32 valA,valB,pc;
    i5 regw;
    // logic rm;
    logic wen,hi_w,lo_w,t;
} W_type;
// typedef logic[31:0] word_t;
typedef logic[4:0] creg_addr_t;
typedef enum i6 {
    OP_RTYPE = 6'b000000,
    OP_BTYPE = 6'b000001,
    OP_J     = 6'b000010,
    OP_JAL   = 6'b000011,
    OP_BEQ   = 6'b000100,
    OP_BNE   = 6'b000101,
    OP_BLEZ  = 6'b000110,
    OP_BGTZ  = 6'b000111,
    OP_ADDI  = 6'b001000,
    OP_ADDIU = 6'b001001,
    OP_SLTI  = 6'b001010,
    OP_SLTIU = 6'b001011,
    OP_ANDI  = 6'b001100,
    OP_ORI   = 6'b001101,
    OP_XORI  = 6'b001110,
    OP_LUI   = 6'b001111,
    OP_COP0  = 6'b010000,
    OP_LB    = 6'b100000,
    OP_LH    = 6'b100001,
    OP_LW    = 6'b100011,
    OP_LBU   = 6'b100100,
    OP_LHU   = 6'b100101,
    OP_SB    = 6'b101000,
    OP_SH    = 6'b101001,
    OP_SW    = 6'b101011
} opcode_t;
typedef enum i6 {
    FN_SLL     = 6'b000000,
    FN_SRL     = 6'b000010,
    FN_SRA     = 6'b000011,
    FN_SRLV    = 6'b000110,
    FN_SRAV    = 6'b000111,
    FN_SLLV    = 6'b000100,
    FN_JR      = 6'b001000,
    FN_JALR    = 6'b001001,
    FN_SYSCALL = 6'b001100,
    FN_BREAK   = 6'b001101,
    FN_MFHI    = 6'b010000,
    FN_MTHI    = 6'b010001,
    FN_MFLO    = 6'b010010,
    FN_MTLO    = 6'b010011,
    FN_MULT    = 6'b011000,
    FN_MULTU   = 6'b011001,
    FN_DIV     = 6'b011010,
    FN_DIVU    = 6'b011011,
    FN_ADD     = 6'b100000,
    FN_ADDU    = 6'b100001,
    FN_SUB     = 6'b100010,
    FN_SUBU    = 6'b100011,
    FN_AND     = 6'b100100,
    FN_OR      = 6'b100101,
    FN_XOR     = 6'b100110,
    FN_NOR     = 6'b100111,
    FN_SLT     = 6'b101010,
    FN_SLTU    = 6'b101011
} funct_t;
parameter BGEZ = 5'b00001;
parameter BLTZ = 5'b00000;
parameter BLTZAL =5'b10000 ;
parameter BGEZAL =5'b10001 ;
`endif