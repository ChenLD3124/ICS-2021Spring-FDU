`include "pipeline.svh"
module execute(
    input E_type E,
    output M_type M_pre
);
    always_comb begin
        M_pre='0;
        M_pre.OP=E.OP;
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
                    FN_SLLV: M_pre.valA=M_pre.valA=E.valB<<E.valA[4:0];
                    FN_SRAV: M_pre.valA=signed'(E.valB)>>>E.valA[4:0];
                    FN_SRLV: M_pre.valA=E.valB>>E.valA[4:0];
                    default:;
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