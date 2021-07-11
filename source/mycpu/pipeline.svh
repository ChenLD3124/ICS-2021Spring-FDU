`ifndef __PIPELINE_SVH__
`define __PIPELINE_SVH__
`include "common.svh"
typedef struct packed {
    logic INT,MOD,TLBL,TLBS,ADEL,ADES,SYS,BP,RI,CPU,OV,TR;
    logic wen,EXL,eret,t;
    logic [4:0] regw;
} EXP_sig;

typedef enum i5 { 
    INT  = 5'h00,
    MOD  = 5'h01,
    TLBL = 5'h02,
    TLBS = 5'h03,
    ADEL = 5'h04,
    ADES = 5'h05,
    SYS  = 5'h08,
    BP   = 5'h09,
    RI   = 5'h0a,
    CPU  = 5'h0b,
    OV   = 5'h0c,
    TR   = 5'h0d
} ExcCode_t;
typedef enum i8 { 
    INDEX   = {5'h00,3'h0},
    RANDOM  = {5'h01,3'h0},
    ENTRYLO0= {5'h02,3'h0},
    ENTRYLO1= {5'h03,3'h0},
    CONTEXT = {5'h04,3'h0},
    PAGEMASK= {5'h05,3'h0},
    WIRED   = {5'h06,3'h0},
    BADVADDR= {5'h08,3'h0},
    COUNT   = {5'h09,3'h0},
    ENTRYHI = {5'h0a,3'h0},
    COMPARE = {5'h0b,3'h0},
    STATUS  = {5'h0c,3'h0},
    CAUSE   = {5'h0d,3'h0},
    EPC_    = {5'h0e,3'h0},
    PRID    = {5'h0f,3'h0},
    CONFIG  = {5'h10,3'h0},
    CONFIG1 = {5'h10,3'h1}
} CP0_reg_t;
typedef struct packed {
    i32 index,random,entrylo0,entrylo1,Context,pagemask,wired,badvaddr,count,entryhi,compare,EPC,status,cause,prid,Config,config1;
} CP0_t;
typedef struct packed {
    i32 pc;
    logic cp0_int;
} F_type;
typedef struct packed {
    i32 pc,imp;
    EXP_sig exp;
} D_type;
typedef struct packed {
    i6 OP,FN;
    i5 regw,sa;
    i32 valA,valB,valC,valD,pc;
    logic hi_w,lo_w,t;
    EXP_sig exp;
} E_type;
typedef struct packed {
    i6 OP;
    i32 valA,valB,pc,pc_l;
    logic rm,wm,hi_w,lo_w;
    i5 regw;
    EXP_sig exp;
} M_type;
typedef struct packed {
    i32 valA,valB,pc;
    i5 regw;
    // logic rm;
    logic wen,hi_w,lo_w;
} W_type;
// typedef logic[31:0] word_t;
typedef struct packed {
    logic [18:0] vpn2;
    logic [7:0] asid;
    logic G;
    logic [19:0] pfn0, pfn1;
    logic [2:0] C0, C1;
    logic V0, V1, D0, D1;
} tlb_entry_t;
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
    OP_SP2   = 6'b011100,
    OP_LB    = 6'b100000,
    OP_LH    = 6'b100001,
    OP_LW    = 6'b100011,
    OP_LBU   = 6'b100100,
    OP_LHU   = 6'b100101,
    OP_SB    = 6'b101000,
    OP_SH    = 6'b101001,
    OP_SW    = 6'b101011,
    OP_LWL   = 6'b100010,
    OP_LWR   = 6'b100110,
    OP_SWL   = 6'b101010,
    OP_SWR   = 6'b101110,
    OP_LL    = 6'b110000,
    OP_SC    = 6'b111000,
    OP_PREF  = 6'b110011
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
    FN_SLTU    = 6'b101011,
    FN_TEQ     = 6'b110100,
    FN_TGE     = 6'b110000,
    FN_TGEU    = 6'b110001,
    FN_TLT     = 6'b110010,
    FN_TLTU    = 6'b110011,
    FN_TNE     = 6'b110110,
    FN_MOVN    = 6'b001011,
    FN_MOVZ    = 6'b001010,
    FN_SYNC    = 6'b001111
} funct_t;
typedef enum i6 { 
    FN_CLZ   = 6'b100000,
    FN_CLO   = 6'b100001,
    FN_MUL   = 6'b000010,
    FN_MADD  = 6'b000000,
    FN_MADDU = 6'b000001,
    FN_MSUB  = 6'b000100,
    FN_MSUBU = 6'b000101
} funct2_t;
typedef enum i5 { 
    BGEZ   = 5'b00001,
    BLTZ   = 5'b00000,
    BLTZAL = 5'b10000,
    BGEZAL = 5'b10001,
    TEQI   = 5'b01100,
    TGEI   = 5'b01000,
    TGEIU  = 5'b01001,
    TLTI   = 5'b01010,
    TLTIU  = 5'b01011,
    TNEI   = 5'b01110
} funct3_t;
parameter int TABEL_ENTRIES=16;
typedef struct packed {
	logic is_tlbwi;
	i32 entryhi;
	i32 entrylo0, entrylo1;
	i32 index;
} tu_op_req_t;
    
typedef struct packed {
	i32 entryhi;
	i32 entrylo0, entrylo1;
	i32 index;
	logic i_tlb_invalid; // && req
	logic i_tlb_modified; // && is store
	logic d_tlb_invalid; // && req
	logic d_tlb_modified; // && is store
	logic i_tlb_refill;
	logic d_tlb_refill;
	logic i_mapped;
	logic d_mapped;
} tu_op_resp_t;
typedef struct packed {
	logic  req;
	word_t vaddr;
} tu_addr_req_t;
typedef struct packed {
	logic  is_uncached;
	word_t paddr;
} tu_addr_resp_t;
`endif