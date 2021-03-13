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
    output logic F_st,D_st,E_bb
);
    i32 pc_nxt;
    always_comb begin
        pc_nxt='0;
        F_st='0;D_st='0;E_bb='0;
        E_pre='0;
        E_pre.OP = D.imp[31:26];
        E_pre.FN = D.imp[5:0];
        E_pre.pc=D.pc;
        pc_decode='0;ra1='0;ra2='0;
        ifj='0;
        //decode
        unique case (E_pre.OP)
            OP_RTYPE:begin
                E_pre.regw=D.imp[15:11];
                ra1=D.imp[25:21];ra2=D.imp[20:16];
                E_pre.valA=rd1;
                E_pre.valB=rd2;
                //memory data crush
                if (ra1==regw_memory) begin
                    if (rdmem_m==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valA=regval_memory;
                    end
                end
                if (ra2==regw_memory) begin
                    if (rdmem_m==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valB=regval_memory;
                    end
                end
                if(regw_execute==regw_memory)begin
                    F_st='0;D_st='0;E_bb='0;
                end
                //execute data crush
                if (ra1==regw_execute) begin
                    if (rdmem==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valA=regval_execute;
                    end
                end
                if (ra2==regw_execute) begin
                    if (rdmem==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valB=regval_execute;
                    end
                end
                E_pre.sa=D.imp[10:6];
                if (E_pre.FN==FN_JR) begin
                    pc_decode=E_pre.valA;
                    ifj=1'b1;
                    E_pre.sa='0;
                end
            end
            OP_ADDIU,OP_SLTI,OP_SLTIU,OP_ANDI,OP_ORI,OP_XORI,OP_LUI,OP_LW:begin
                ra1=D.imp[25:21];E_pre.valA=rd1;
                E_pre.regw=D.imp[20:16];
                //memory data crush
                if (ra1==regw_memory) begin
                    if (rdmem_m==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valA=regval_memory;
                    end
                end
                if(regw_execute==regw_memory)begin
                    F_st='0;D_st='0;E_bb='0;
                end
                if (ra1==regw_execute) begin
                    if(rdmem==1'b1)begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valA=regval_execute;
                    end
                end
                if(E_pre.OP==OP_ADDIU||E_pre.OP==OP_SLTI||E_pre.OP==OP_SLTIU||E_pre.OP==OP_LW)begin
                    E_pre.valB=signed'(D.imp[15:0]);
                end else begin
                    E_pre.valB=D.imp[15:0];
                end
            end
            OP_SW:begin
                ra1=D.imp[25:21];ra2=D.imp[20:16];
                E_pre.valA=rd1;E_pre.valC=rd2;
                //memory data crush
                if (ra1==regw_memory) begin
                    if (rdmem_m==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valA=regval_memory;
                    end
                end
                if (ra2==regw_memory) begin
                    if (rdmem_m==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valC=regval_memory;
                    end
                end
                if(regw_execute==regw_memory)begin
                    F_st='0;D_st='0;E_bb='0;
                end
                //execute crush
                if (ra1==regw_execute) begin
                    if (rdmem==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valA=regval_execute;
                    end
                end
                if (ra2==regw_execute) begin
                    if (rdmem==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valC=regval_execute;
                    end
                end
                E_pre.valB=signed'(D.imp[15:0]);
            end
            OP_J,OP_JAL:begin
                ifj=1'b1;
                pc_nxt=D.pc+32'h4;//!!!
                pc_decode={pc_nxt[31:28],D.imp[25:0],2'b00};
                if(E_pre.OP==OP_JAL)begin
                    E_pre.regw=5'b11111;
                    E_pre.valA=D.pc;
                    E_pre.valB=32'b1000;
                end
            end
            OP_BEQ,OP_BNE:begin
                pc_nxt=signed'(D.imp[15:0]<<2);
                pc_decode=D.pc+pc_nxt+32'h4;//!!!
                ra1=D.imp[25:21];ra2=D.imp[20:16];
                E_pre.valA=rd1;E_pre.valB=rd2;
                //memory data crush
                if (ra1==regw_memory) begin
                    if (rdmem_m==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valA=regval_memory;
                    end
                end
                if (ra2==regw_memory) begin
                    if (rdmem_m==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valB=regval_memory;
                    end
                end
                if(regw_execute==regw_memory)begin
                    F_st='0;D_st='0;E_bb='0;
                end
                //execute crush
                if (ra1==regw_execute) begin
                    if (rdmem==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valA=regval_execute;
                    end
                end
                if (ra2==regw_execute) begin
                    if (rdmem==1'b1) begin
                        F_st='1;D_st='1;E_bb='1;
                    end else begin
                        E_pre.valB=regval_execute;
                    end
                end
                if (E_pre.valA==E_pre.valB&&E_pre.OP==OP_BEQ) begin
                    ifj=1'b1;
                end else if (E_pre.valA!=E_pre.valB&&E_pre.OP==OP_BNE) begin
                    ifj=1'b1;
                end
            end
        endcase
    end
endmodule