`include "pipeline.svh"
module decode(
    input D_type D,
    // input i32 D_imp,
    output creg_addr_t ra1,ra2,
    input word_t rd1,rd2,
    output E_type E_pre,
    output i32 pc_decode,
    output logic ifj,
    input creg_addr_t regw_execute,regw_memory,
    input word_t regval_execute,regval_memory,
    input logic rdmem,rdmem_m,
    output logic pcf1,
    input i32 hi_new,lo_new,
    input logic e_hi,e_lo,m_hi,m_lo,
    input i32 regval_elo,regval_mlo,
    input CP0_t CP0_nxt,
    input i1 E_cpw,
    input i5 E_cpr
);
    i32 pc_nxt,hd1,hd2,hd3,hd4,cpa;
    assign hd3 = e_hi?regval_execute:(m_hi?regval_memory:hi_new);
    assign hd4 = e_lo?regval_elo:(m_lo?regval_mlo:lo_new);
    always_comb begin
        pcf1='0;
        hd1=rd1;
        hd2=rd2;
        //memory data crush
        if (ra1!=5'b0&&ra1==regw_memory) begin
            hd1=regval_memory;
        end
        if (ra2!=5'b0&&ra2==regw_memory) begin
            hd2=regval_memory;
        end
        //execute data crush
        if (ra1!=5'b0&&ra1==regw_execute) begin
            if (rdmem==1'b1) begin
                pcf1='1;
            end else begin
                hd1=regval_execute;
            end
        end
        if (ra2!=5'b0&&ra2==regw_execute) begin
            if (rdmem==1'b1) begin
                pcf1='1;
            end else begin
                hd2=regval_execute;
            end
        end
    end
    always_comb begin
        cpa='0;
        if (D.imp[31:26]==OP_COP0&&D.imp[25:21]==5'b00000) begin
            unique case (D.imp[15:11])
                5'b01000: cpa=CP0_nxt.badvaddr;
                5'b01001: cpa=CP0_nxt.count;
                5'b01011: cpa=CP0_nxt.compare;
                5'b01100: cpa=CP0_nxt.status;
                5'b01101: cpa=CP0_nxt.cause;
                5'b01110: cpa=CP0_nxt.EPC;
                default: cpa='0;
            endcase
            if (E_cpw&&D.imp[15:11]==E_cpr) begin
                cpa=regval_execute;
            end
            
        end
    end
    always_comb begin
        ra1='0;ra2='0;
        unique case (D.imp[31:26])
            OP_RTYPE,OP_BEQ,OP_BNE,OP_SW,OP_SH,OP_SB,OP_SWL,OP_SWR,OP_LWL,OP_LWR:begin ra1=D.imp[25:21];ra2=D.imp[20:16]; end
            OP_ADDIU,OP_SLTI,OP_SLTIU,OP_ANDI,OP_ORI,OP_XORI,OP_LUI,OP_LW,OP_ADDI,
                OP_BGTZ,OP_BLEZ,OP_BTYPE,OP_LB,OP_LBU,OP_LH,OP_LHU:begin
                ra1=D.imp[25:21];
            end
            OP_COP0:begin
                if (D.imp[25:21]==5'b00100) begin
                    ra1=D.imp[20:16];
                end
            end
            OP_SP2:begin
                if (D.imp[5:0]==FN_CLZ||D.imp[5:0]==FN_CLO) begin
                    ra1=D.imp[25:21];
                end
                else begin
                    ra1=D.imp[25:21];ra2=D.imp[20:16];
                end
            end
            default:;
        endcase
    end
    always_comb begin
        pc_nxt='0;
        E_pre='0;
        E_pre.OP = D.imp[31:26];
        E_pre.FN = D.imp[5:0];
        E_pre.pc=D.pc;
        pc_decode='0;
        ifj='0;
        E_pre.exp=D.exp;
        E_pre.exp.EXL=CP0_nxt.status[1];
        // E_pre.exp.INT=cp0_int;
        //decode
        unique case (E_pre.OP)
            OP_RTYPE:begin
                E_pre.regw=D.imp[15:11];
                unique case (D.imp[5:0])
                    FN_MTHI:begin
                        E_pre.hi_w='1;
                        E_pre.valA=hd1;
                    end
                    FN_MTLO:begin
                        E_pre.lo_w='1;
                        E_pre.valB=hd1;
                    end
                    FN_MFHI:begin
                        E_pre.valA=hd3;
                    end
                    FN_MFLO:begin
                        E_pre.valA=hd4;
                    end
                    FN_JR:begin
                        pc_decode=hd1;
                        ifj=1'b1;
                        E_pre.t='1;
                    end
                    FN_JALR:begin
                        pc_decode=hd1;
                        E_pre.valA=D.pc;
                        E_pre.valB=32'b1000;
                        ifj='1;
                        E_pre.t='1;
                    end
                    FN_BREAK:begin
                        E_pre.exp.BP='1;
                    end
                    FN_SYSCALL:begin
                        E_pre.exp.SYS='1;
                    end
                    FN_SLL,FN_SRL,FN_SRA,FN_SRLV,FN_SRAV,FN_SLLV,FN_MULT,
                    FN_MULTU,FN_DIV,FN_DIVU,FN_ADD,FN_ADDU,FN_SUB,FN_SUBU,
                    FN_AND,FN_OR,FN_XOR,FN_NOR,FN_SLT,FN_SLTU,FN_MOVN,FN_MOVZ,
                    FN_TEQ,FN_TGE,FN_TGEU,FN_TLT,FN_TLTU,FN_TNE:begin
                        E_pre.valA=hd1;E_pre.valB=hd2;
                        E_pre.sa=D.imp[10:6];
                    end
                    default:begin
                        E_pre.exp.RI='1;
                    end
                endcase
            end
            OP_ADDIU,OP_ADDI,OP_SLTI,OP_SLTIU,OP_ANDI,OP_ORI,OP_XORI,OP_LUI,OP_LW,OP_LB,OP_LH,OP_LBU,OP_LHU:begin
                E_pre.regw=D.imp[20:16];
                E_pre.valA=hd1;
                if(E_pre.OP!=OP_ANDI&&E_pre.OP!=OP_ORI&&E_pre.OP!=OP_XORI&&E_pre.OP!=OP_LUI)begin
                    E_pre.valB=i32'(signed'(D.imp[15:0]));
                end else begin
                    E_pre.valB=i32'(D.imp[15:0]);
                end
            end
            OP_SW,OP_SB,OP_SH:begin
                E_pre.valA=hd1;E_pre.valC=hd2;
                E_pre.valB=i32'(signed'(D.imp[15:0]));
            end
            OP_J,OP_JAL:begin
                ifj=1'b1;
                E_pre.t='1;
                pc_nxt=D.pc+32'h4;//!!!
                pc_decode={pc_nxt[31:28],D.imp[25:0],2'b00};
                if(E_pre.OP==OP_JAL)begin
                    E_pre.regw=5'b11111;
                    E_pre.valA=D.pc;
                    E_pre.valB=32'b1000;
                end
            end
            OP_BEQ,OP_BNE:begin
                // pc_nxt=i32'(signed'(D.imp[15:0]<<2));
                pc_nxt={{14{D.imp[15]}},D.imp[15:0],2'b00};
                pc_decode=D.pc+pc_nxt+32'h4;//!!!
                E_pre.valA=hd1;E_pre.valB=hd2;
                E_pre.t='1;
                if (E_pre.valA==E_pre.valB&&E_pre.OP==OP_BEQ) begin
                    ifj=1'b1;
                end else if (E_pre.valA!=E_pre.valB&&E_pre.OP==OP_BNE) begin
                    ifj=1'b1;
                end
            end
            OP_BGTZ,OP_BLEZ:begin
                // pc_nxt=i32'(signed'(D.imp[15:0]<<2));
                pc_nxt={{14{D.imp[15]}},D.imp[15:0],2'b00};
                pc_decode=D.pc+pc_nxt+32'h4;//!!!
                E_pre.valA=hd1;
                E_pre.t='1;
                if(E_pre.OP==OP_BGTZ&&signed'(E_pre.valA)>0)begin
                    ifj=1'b1;
                end else if (E_pre.OP==OP_BLEZ&&signed'(E_pre.valA)<=0) begin
                    ifj=1'b1;
                end
            end
            OP_BTYPE:begin
                // pc_nxt=i32'(signed'(D.imp[15:0]<<2));
                pc_nxt={{14{D.imp[15]}},D.imp[15:0],2'b00};
                pc_decode=D.pc+pc_nxt+32'h4;//!!!
                E_pre.valC=hd1;
                unique case (D.imp[20:16])
                    BGEZ:begin E_pre.t='1;if(signed'(E_pre.valC)>=0)begin ifj='1;end end
                    BLTZ:begin E_pre.t='1;if(signed'(E_pre.valC)<0)begin ifj='1;end end
                    BLTZAL,BGEZAL:begin
                        E_pre.t='1;
                        if(D.imp[20:16]==BLTZAL&&signed'(E_pre.valC)<0)begin ifj='1;end
                        else if(D.imp[20:16]==BGEZAL&&signed'(E_pre.valC)>=0)begin ifj='1;end
                        E_pre.regw=5'b11111;
                        E_pre.valA=D.pc;
                        E_pre.valB=32'b1000;
                    end
                    TEQI:begin
                        if(signed'(hd1)==i32'(signed'(D.imp[15:0]))) E_pre.exp.TR='1;
                    end
                    TGEI:begin
                        if(signed'(hd1)>=i32'(signed'(D.imp[15:0]))) E_pre.exp.TR='1;
                    end
                    TLTI:begin
                        if(signed'(hd1)<i32'(signed'(D.imp[15:0]))) E_pre.exp.TR='1;
                    end
                    TNEI:begin
                        if(signed'(hd1)!=i32'(signed'(D.imp[15:0]))) E_pre.exp.TR='1;
                    end
                    TGEIU:begin
                        if(hd1>=i32'(D.imp[15:0])) E_pre.exp.TR='1;
                    end
                    TLTIU:begin
                        if(hd1<i32'(D.imp[15:0])) E_pre.exp.TR='1;
                    end
                    default:begin
                        E_pre.exp.RI='1;
                    end
                endcase
            end
            OP_COP0:begin
                unique case (D.imp[25:21])
                    5'b00000:begin//MF
                        E_pre.regw=D.imp[20:16];
                        E_pre.valA=cpa;
                    end
                    5'b00100:begin//MT
                        E_pre.valA=hd1;
                        E_pre.exp.regw=D.imp[15:11];
                        E_pre.exp.wen='1;
                    end
                    default:begin
                        if (D.imp[25]) begin
                            E_pre.valA=CP0_nxt.EPC;
                            E_pre.exp.eret='1;
                        end
                        else begin
                            E_pre.exp.RI='1;
                        end
                    end
                endcase
            end
            OP_SP2:begin
                E_pre.regw=D.imp[15:11];
                unique case (D.imp[5:0])
                    FN_CLZ,FN_CLO:begin
                        E_pre.valA=hd1;
                    end
                    FN_MUL:begin
                        E_pre.valA=hd1;E_pre.valB=hd2;
                    end
                    FN_MADD,FN_MADDU,FN_MSUB,FN_MSUBU:begin
                        E_pre.valA=hd1;E_pre.valB=hd2;
                        E_pre.valC=hd3;E_pre.valD=hd4;
                        E_pre.hi_w='1;E_pre.lo_w='1;
                    end
                    default:E_pre.exp.RI='1;
                endcase
            end
            OP_LWL,OP_LWR,OP_SWL,OP_SWR:begin
                E_pre.valA=hd1;E_pre.valC=hd2;
                E_pre.valB=i32'(signed'(D.imp[15:0]));
                if(D.imp[31:26]==OP_LWL||D.imp[31:26]==OP_LWR) E_pre.regw=D.imp[20:16];
            end
            default:begin
                E_pre.exp.RI='1;
            end
        endcase
    end
endmodule