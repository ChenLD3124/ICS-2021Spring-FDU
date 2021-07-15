`include "common.svh"
`include "pipeline.svh"
module MyCore (
    input logic clk, resetn,
    output ibus_req_t  ireq,
    input  ibus_resp_t iresp,
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp,
    input i6 ext_int,
    output tu_op_req_t tu_op_req,
    output i1 k0_uncached,is_store,
    input tu_op_resp_t tu_op_resp,
);
    /**
     * TODO (Lab1) your code here :)
     */
    //define the variable

    //pipeline reg
    F_type F,F_pre;
    D_type D,D_pre;
    E_type E,E_pre;
    M_type M,M_pre;
    W_type W_pre,W;
    i32 Dpc/* verilator public_flat_rd */;
    logic Dwen/* verilator public_flat_rd */;
    i5 Dwnum/* verilator public_flat_rd */;
    assign Dpc=W.pc;  
    assign Dwen=W.wen;
    assign Dwnum=W.regw;
    //wire for link regfile
    creg_addr_t ra1,ra2,wa3;
    logic write_enable,hi_write,lo_write;
    word_t hi_new,lo_new,hi_data,lo_data,rd1,rd2,wd3/* verilator public_flat_rd */;
    i32 pc_decode,pc_fetch;
    logic ifj,pcf1,pcf2,pcf3,pcf4;
    logic F_st,D_st,EM_st;
    logic D_bb,E_bb,M_bb,W_bb;
    i5 regw_execute,regw_memory;
    i32 regval_execute,regval_memory,regval_elo,regval_mlo;
    logic rdmem,rdmem_m;
    i32 dresp_data;
    logic e_hi,e_lo,m_hi,m_lo,time_int,cp0_t;
    i8 int_info;
    logic exp,cp0_tmp,cp0_wen,cp0_wf,cp0_badwen,time_clear,M_index,M_hi,M_lo0,M_lo1;
    i5 cp0_regw,excode;
    i32 cp0_wdata,cp0_badvaddr;
    //CP0
    CP0_t CP0,CP0_nxt;
    i32 CP0_d,D_EPC;
    i1 D_EXL;
    assign D_EXL = CP0_nxt.status[1];
    assign D_EPC = CP0_nxt.EPC;
    always_comb begin
        unique case ({D.imp[15:11],D.imp[2:0]})
            INDEX   :CP0_d=CP0.index;
            ENTRYLO0:CP0_d=CP0.entrylo0;
            ENTRYLO1:CP0_d=CP0.entrylo1;
            CONTEXT :CP0_d=CP0.Context;
            WIRED   :CP0_d=CP0.wired;
            BADVADDR:CP0_d=CP0.badvaddr;
            COUNT   :CP0_d=CP0.count;
            ENTRYHI :CP0_d=CP0.entryhi;
            COMPARE :CP0_d=CP0.compare;
            STATUS  :CP0_d=CP0.status;
            CAUSE   :CP0_d=CP0.cause;
            EPC_    :CP0_d=CP0.EPC;
            PRID    :CP0_d=CP0.prid;
            CONFIG  :CP0_d=CP0.Config;
            CONFIG1 :CP0_d=CP0.config1;
            default: CP0_d='0;
        endcase
    end
    assign tu_op_req.index   = CP0.index;
    assign tu_op_req.entryhi = CP0.entryhi;
    assign tu_op_req.entrylo0= CP0.entrylo0;
    assign tu_op_req.entrylo1= CP0.entrylo1;
    assign tu_op_req.is_tlbwi = M.tlbwi&(exp=='0);
    assign k0_uncached  = CP0.Config[2:0]!=3'd3;
    logic i_tlb_invalid,i_tlb_refill,d_tlb_invalid,d_tlb_modified,d_tlb_refill,BEV;
    assign i_tlb_refill = tu_op_resp.i_tlb_refill;
    assign i_tlb_invalid = tu_op_resp.i_tlb_invalid;
    assign d_tlb_invalid = tu_op_resp.d_tlb_invalid;
    assign d_tlb_modified = tu_op_resp.d_tlb_modified;
    assign d_tlb_refill = tu_op_resp.d_tlb_refill;
    assign BEV = CP0.status[22:22];
    //
    assign F_pre.cp0_int = CP0_nxt.status[0]&(~CP0_nxt.status[1])&(int_info!='0);
    assign int_info = ({ext_int, 2'b00}|CP0_nxt.cause[15:8]|{time_int, 7'b0})&CP0_nxt.status[15:8];
    assign regval_execute = M_pre.valA;
    assign regw_execute = E.regw;
    assign regval_memory = W_pre.valA;
    assign regw_memory = M.regw;
    assign rdmem = M_pre.rm;
    assign rdmem_m = M.rm;
    assign {e_hi,e_lo,m_hi,m_lo} = {M_pre.hi_w,M_pre.lo_w,M.hi_w,M.lo_w};
    assign regval_elo = M_pre.valB;
    assign regval_mlo = W_pre.valB;
    assign cp0_t = E_pre.t;
    i32 D_pc;
    i12 offset;
    assign D_pc = D.pc;
    //module
    fetch fetch_c(.*);
    decode decode_c(.*);
    execute execute_c(.*);
    memory memory_c(.*);
    write_back write_back_c(.*);
    regfile reg_c(.*);
    hilo hilo_c(.*);
    //
    pc_selector pcSelector(
        .nxt_pc(F_pre.pc),
        .exp,.eret(M.exp.eret),.ifj,.pc_decode,.pc_fetch,.EPC(M.valA),
        .cp0_flush(cp0_wf),.E_pc(M.pc_l),.offset,.BEV(CP0_nxt.status[22:22])
    );
    //
    assign is_store = M.wm;
    assign cp0_wf = cp0_wen|M_index|M_hi|M_lo0|M_lo1|M.tlbwi;
    always_comb begin
        CP0_nxt=CP0;
        CP0_nxt.count=CP0.count+i32'(cp0_tmp);
        time_clear='0;
        if(cp0_wen)begin
            priority case (cp0_regw)
                5'b01000: CP0_nxt.badvaddr=cp0_wdata;
                5'b01001: CP0_nxt.count=cp0_wdata;
                5'b01011: begin CP0_nxt.compare=cp0_wdata;time_clear='1;end
                5'b01100: CP0_nxt.status=cp0_wdata;
                5'b01101: CP0_nxt.cause=cp0_wdata;
                5'b01110: CP0_nxt.EPC=cp0_wdata;
                default:;
            endcase
        end
        if(M_index) CP0_nxt.index=M.valA;;
        if(M_hi) CP0_nxt.entryhi=M.valA;
        if(M_lo0) CP0_nxt.entrylo0=M.valB;
        if(M_lo1) CP0_nxt.entrylo1=M.valC;
        if (exp) begin
            if (cp0_badwen) begin
                CP0_nxt.badvaddr=cp0_badvaddr;
            end
            if (excode==TLBL||excode==TLBS||excode==MOD) begin
                CP0_nxt.entryhi[31:13]=cp0_badvaddr[31:13];
                CP0_nxt.Context[22:4]=cp0_badvaddr[31:13];
            end
            CP0_nxt.cause[6:2]=excode;
            if (M.exp.EXL==1'b0) begin
                if (M.exp.t) begin
                    CP0_nxt.EPC=M.pc-4;
                    CP0_nxt.cause[31]='1;
                end
                else begin
                    CP0_nxt.EPC=M.pc;
                    CP0_nxt.cause[31]='0;
                end
            end
            CP0_nxt.status[1]='1;
        end
        else if (M.exp.eret) begin
            CP0_nxt.status[1]='0;
        end
    end
    //control
    always_comb begin
        F_st='0;D_st='0;D_bb='0;E_bb='0;EM_st='0;M_bb='0;W_bb='0;
        if (pcf1==1'b1||pcf2==1'b1) begin
            F_st='1;D_st='1;E_bb='1;
        end
        if (pcf3==1'b1||pcf4==1'b1) begin
            F_st='1;D_st='1;EM_st='1;W_bb='1;
        end
        if (F_st&(exp|M.exp.eret|cp0_wf)) begin
            D_st='1;EM_st='1;W_bb='1;
        end
    end
    always_ff @(posedge clk) begin
        if (resetn) begin
        // AHA!
            if (F_st!=1'b1) begin
                F<=F_pre;
            end
            if(D_st!=1'b1) begin
                if ( D_bb|exp|M.exp.eret|cp0_wf) begin
                    D<='0;
                end else begin
                    D<=D_pre;
                end
            end
            if(EM_st!= 1'b1) begin
                if (E_bb|exp|M.exp.eret|cp0_wf) begin
                    E<='0;
                end else begin
                    E<=E_pre;
                end
                if (M_bb|exp|M.exp.eret|cp0_wf) begin
                    M<='0;
                end else begin
                    M<=M_pre;
                end
            end
            if (W_bb|exp|M.exp.eret|cp0_wen) begin
                W<='0;
            end else begin
                W<=W_pre;
            end
            //
            CP0<=CP0_nxt;
            cp0_tmp<=(~cp0_tmp);
            if (time_clear=='0&&CP0_nxt.count==CP0_nxt.compare) begin
                time_int<='1;
            end else if (time_clear) begin
                time_int<='0;
            end
        end else begin
        // reset
        // NOTE: if resetn is X, it will be evaluated to false.
        F.pc<=32'hbfc00000;
        F.cp0_int<='0;
        D<='0;
        E<='0;
        M<='0;
        W<='0;
        CP0<='0;
        cp0_tmp<='0;
        time_int<='0;
        end
    end
    

    // remove following lines when you start
    //assign ireq = '0;
    //assign dreq = '0;
    //`UNUSED_OK({iresp, dresp});
endmodule
