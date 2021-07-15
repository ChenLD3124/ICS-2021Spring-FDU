`include "pipeline.svh"
module execute(
    input logic clk,resetn,
    input i32 D_pc,
    output logic pcf4,
    input E_type E,
    output M_type M_pre
);
    logic valid_m,done_m,valid_d,done_d;
    i32 a,b;
    i64 c_m,c_d,tmp;
    assign pcf4 = E.exp[20:9]!='0?'0:((valid_m&(~done_m))|(valid_d&(~done_d)));
    mult mult_c(.done(done_m),.valid(valid_m),.c(c_m),.*);
    div div_c(.done(done_d),.valid(valid_d),.c(c_d),.*);
    always_comb begin
        a='0;b='0;tmp='0;
        M_pre='0;valid_m='0;valid_d='0;
        M_pre.OP=E.OP;
        {M_pre.hi_w,M_pre.lo_w}={E.hi_w,E.lo_w};
        M_pre.regw=E.regw;
        M_pre.pc=E.pc;
        M_pre.exp=E.exp;
        M_pre.pc_l=D_pc;
        M_pre.tlbwi=E.tlbwi;
        {M_pre.hi_w,M_pre.lo0_w,M_pre.lo1_w,M_pre.index_w}={
            E.hi_w,E.lo0_w,E.lo1_w,E.index_w};
        if (E.exp[20:9]=='0) begin
            unique case (E.OP)
                OP_RTYPE:begin
                    unique case (E.FN)
                        FN_SLL: M_pre.valA=E.valB<<E.sa;
                        FN_SRL: M_pre.valA=E.valB>>E.sa;
                        FN_SRA: M_pre.valA=signed'(E.valB)>>>E.sa;
                        FN_ADDU,FN_JALR: M_pre.valA=E.valA+E.valB;
                        FN_ADD:begin
                            tmp={31'b0,E.valA[31],E.valA}+{31'b0,E.valB[31],E.valB};
                            if (tmp[32]!=tmp[31]) begin
                                M_pre.exp.OV='1;
                            end else begin
                                M_pre.valA=tmp[31:0];
                            end
                        end
                        FN_SUB:begin
                            tmp={31'b0,E.valA[31],E.valA}-{31'b0,E.valB[31],E.valB};
                            if (tmp[32]!=tmp[31]) begin
                                M_pre.exp.OV='1;
                            end else begin
                                M_pre.valA=tmp[31:0];
                            end
                        end
                        FN_SUBU: M_pre.valA=E.valA-E.valB;
                        FN_AND: M_pre.valA=E.valA&E.valB;
                        FN_OR:  M_pre.valA=E.valA|E.valB;
                        FN_XOR: M_pre.valA=E.valA^E.valB;
                        FN_NOR: M_pre.valA=~(E.valA|E.valB);
                        FN_SLT:  M_pre.valA=i32'(signed'(E.valA)<signed'(E.valB));
                        FN_SLTU: M_pre.valA=i32'(E.valA<E.valB);
                        FN_SLLV: M_pre.valA=E.valB<<E.valA[4:0];
                        FN_SRAV: M_pre.valA=signed'(E.valB)>>>E.valA[4:0];
                        FN_SRLV: M_pre.valA=E.valB>>E.valA[4:0];
                        FN_MULTU:begin
                            a=E.valA;
                            b=E.valB;
                            valid_m='1;
                            M_pre.valA=c_m[63:32];
                            M_pre.valB=c_m[31:0];
                            M_pre.hi_w='1;
                            M_pre.lo_w='1;
                        end
                        FN_MULT:begin
                            a=E.valA[31]?((~E.valA)+32'b1):E.valA;
                            b=E.valB[31]?((~E.valB)+32'b1):E.valB;
                            valid_m='1;
                            if(E.valA[31]^E.valB[31]==1'b1)begin
                                tmp=(~c_m)+64'b1;
                            end else begin
                                tmp=c_m;
                            end
                            M_pre.valA=tmp[63:32];
                            M_pre.valB=tmp[31:0];
                            M_pre.hi_w='1;
                            M_pre.lo_w='1;
                        end
                        FN_DIVU:begin
                            a=E.valA;
                            b=E.valB;
                            valid_d='1;
                            M_pre.valA=c_d[63:32];
                            M_pre.valB=c_d[31:0];
                            M_pre.hi_w='1;
                            M_pre.lo_w='1;
                        end
                        FN_DIV:begin
                            a=E.valA[31]?((~E.valA)+32'b1):E.valA;
                            b=E.valB[31]?((~E.valB)+32'b1):E.valB;
                            valid_d='1;
                            if(E.valA[31]^E.valB[31]==1'b1)begin
                                if(E.valA[31]!=1'b1)begin
                                    M_pre.valA=c_d[63:32];
                                    M_pre.valB=(~c_d[31:0])+32'b1;
                                end else begin
                                    M_pre.valA=(~c_d[63:32])+32'b1;
                                    M_pre.valB=(~c_d[31:0])+32'b1;
                                end
                            end else begin
                                M_pre.valA=E.valA[31]?((~c_d[63:32])+32'b1):c_d[63:32];
                                M_pre.valB=c_d[31:0];
                            end
                            M_pre.hi_w='1;
                            M_pre.lo_w='1;
                        end
                        FN_MOVZ:begin
                            M_pre.valA=E.valA;
                            if (E.valB!=0) begin
                                M_pre.regw=0;
                            end
                        end
                        FN_MOVN:begin
                            M_pre.valA=E.valA;
                            if (E.valB==0) begin
                                M_pre.regw=0;
                            end
                        end
                        FN_TEQ:begin
                            if (E.valA==E.valB) begin
                                M_pre.exp.TR='1;
                            end
                        end
                        FN_TGE:begin
                            if (signed'(E.valA)>=signed'(E.valB)) begin
                                M_pre.exp.TR='1;
                            end
                        end
                        FN_TGEU:begin
                            if (E.valA>=E.valB) begin
                                M_pre.exp.TR='1;
                            end
                        end
                        FN_TLT:begin
                            if (signed'(E.valA)<signed'(E.valB)) begin
                                M_pre.exp.TR='1;
                            end
                        end
                        FN_TLTU:begin
                            if (E.valA<E.valB) begin
                                M_pre.exp.TR='1;
                            end
                        end
                        FN_TNE:begin
                            if (E.valA!=E.valB) begin
                                M_pre.exp.TR='1;
                            end
                        end
                        default:begin M_pre.valA=E.valA;M_pre.valB=E.valB;end
                    endcase
                end
                OP_ADDI:begin
                    tmp={31'b0,E.valA[31],E.valA}+{31'b0,E.valB[31],E.valB};
                    if (tmp[32]!=tmp[31]) begin
                        M_pre.exp.OV='1;
                    end else begin
                        M_pre.valA=tmp[31:0];
                    end
                end
                OP_ANDI: M_pre.valA=E.valA&E.valB;
                OP_ORI: M_pre.valA=E.valA|E.valB;
                OP_XORI: M_pre.valA=E.valA^E.valB;
                OP_ADDIU: M_pre.valA=E.valA+E.valB;
                OP_SLTI: M_pre.valA=i32'(signed'(E.valA)<signed'(E.valB));
                OP_SLTIU: M_pre.valA=i32'(E.valA<E.valB);
                OP_LUI: M_pre.valA=E.valB<<16;
                OP_LW,OP_LB,OP_LH,OP_LHU,OP_LBU,OP_LWL,OP_LWR,OP_LL: begin
                    M_pre.valA=E.valA+E.valB;
                    M_pre.rm='1;
                    M_pre.valB=E.valC;
                end
                OP_SW,OP_SB,OP_SH,OP_SWL,OP_SWR,OP_SC: begin
                    M_pre.valA=E.valA+E.valB;
                    M_pre.wm='1;
                    M_pre.valB=E.valC;
                end
                OP_JAL:begin
                    M_pre.valA=E.valA+E.valB;
                end
                OP_BTYPE:begin
                    M_pre.valA=E.valA+E.valB;
                end
                OP_COP0:begin
                    M_pre.valA=E.valA;
                    M_pre.valB=E.valB;
                    M_pre.valC=E.valC;
                end
                OP_SP2:begin
                    unique case (E.FN)
                        FN_CLZ:begin
                            M_pre.valA=32;
                            for (int i=31; i>=0; --i) begin
                                if (E.valA[i]==1) begin
                                    M_pre.valA=31-i;
                                    break;
                                end
                            end
                        end
                        FN_CLO:begin
                            M_pre.valA=32;
                            for (int i=31; i>=0; --i) begin
                                if (E.valA[i]==0) begin
                                    M_pre.valA=31-i;
                                    break;
                                end
                            end
                        end
                        FN_MUL,FN_MADD,FN_MSUB:begin
                            a=E.valA[31]?((~E.valA)+32'b1):E.valA;
                            b=E.valB[31]?((~E.valB)+32'b1):E.valB;
                            valid_m='1;
                            if(E.valA[31]^E.valB[31]==1'b1)begin
                                tmp=(~c_m)+64'b1;
                            end else begin
                                tmp=c_m;
                            end
                            M_pre.valA=tmp[31:0];
                            if (E.FN==FN_MADD) begin
                                tmp+={E.valC,E.valD};
                            end else if (E.FN==FN_MSUB) begin
                                tmp={E.valC,E.valD}-tmp;
                            end
                            if (E.FN!=FN_MUL) begin
                                M_pre.valA=tmp[63:32];M_pre.valB=tmp[31:0];
                                M_pre.hi_w='1;M_pre.lo_w='1;
                            end
                        end
                        FN_MADDU,FN_MSUBU:begin
                            a=E.valA;
                            b=E.valB;
                            valid_m='1;
                            if (E.FN==FN_MADDU) begin
                                tmp={E.valC,E.valD}+c_m;
                            end else begin
                                tmp={E.valC,E.valD}-c_m;
                            end
                            M_pre.valA=tmp[63:32];
                            M_pre.valB=tmp[31:0];
                            M_pre.hi_w='1;M_pre.lo_w='1;
                        end
                        default:;
                    endcase
                end
                default:;
            endcase
        end
        
    end
endmodule