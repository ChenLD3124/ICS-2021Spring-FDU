`include "pipeline.svh"
module execute(
    input logic clk,resetn,
    output logic pcf4,
    input E_type E,
    output M_type M_pre
);
    logic valid_m,done_m,valid_d,done_d;
    i32 a,b;
    i64 c_m,c_d;
    assign pcf4 = (valid_m&(~done_m))|(valid_d&(~done_d));
    multiplier_multicycle_from_single mult_c(.done(done_m),.valid(valid_m),.c(c_m),.*);
    divider_multicycle_from_single div_c(.done(done_d),.valid(valid_d),.c(c_d),.*);
    always_comb begin
        a='0;b='0;
        M_pre='0;valid_m='0;valid_d='0;
        M_pre.OP=E.OP;
        {M_pre.hi_r,M_pre.hi_w,M_pre.lo_r,M_pre.lo_w}={E.hi_r,E.hi_w,E.lo_r,E.lo_w};
        M_pre.regw=E.regw;
        M_pre.pc=E.pc;
        unique case (E.OP)
            OP_RTYPE:begin
                unique case (E.FN)
                    FN_SLL: M_pre.valA=E.valB<<E.sa;
                    FN_SRL: M_pre.valA=E.valB>>E.sa;
                    FN_SRA: M_pre.valA=signed'(E.valB)>>>E.sa;
                    FN_ADDU,FN_JALR: M_pre.valA=E.valA+E.valB;
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
                            M_pre.valA=((~c_m)+64'b1)[63:32];
                            M_pre.valB=((~c_m)+64'b1)[31:0];
                        end else begin
                            M_pre.valA=c_m[63:32];
                            M_pre.valB=c_m[31:0];
                        end
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
                            if(E.valA[31]==1'b1)begin
                                M_pre.valA=c_d[63:32];
                                M_pre.valB=(~c_d[31:0])+32'b1;
                            end else begin
                                M_pre.valA=(~c_d[63:32])+32'b1;
                                M_pre.valB=(~c_d[31:0])+32'b1;
                            end
                        end else begin
                            M_pre.valA=c_d[63:32];
                            M_pre.valB=c_d[31:0];
                        end
                    end
                    default:begin M_pre.valA=E.valA;M_pre.valB=E.valB;end
                endcase
            end
            OP_ANDI: M_pre.valA=E.valA&E.valB;
            OP_ORI: M_pre.valA=E.valA|E.valB;
            OP_XORI: M_pre.valA=E.valA^E.valB;
            OP_ADDIU: M_pre.valA=E.valA+E.valB;
            OP_SLTI: M_pre.valA=i32'(signed'(E.valA)<signed'(E.valB));
            OP_SLTIU: M_pre.valA=i32'(E.valA<E.valB);
            OP_LUI: M_pre.valA=E.valB<<16;
            OP_LW,OP_LB,OP_LH,OP_LHU,OP_LBU: begin
                M_pre.valA=E.valA+E.valB;
                M_pre.rm='1;
            end
            OP_SW,OP_SB,OP_SH: begin
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
            default:;
        endcase
    end
endmodule