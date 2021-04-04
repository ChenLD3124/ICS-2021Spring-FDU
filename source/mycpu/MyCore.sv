`include "common.svh"
`include "pipeline.svh"
module MyCore (
    input logic clk, resetn,

    output ibus_req_t  ireq,
    input  ibus_resp_t iresp,
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp
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
    logic e_hi,e_lo,m_hi,m_lo;
    assign regval_execute = M_pre.valA;
    assign regw_execute = E.regw;
    assign regval_memory = W_pre.valA;
    assign regw_memory = M.regw;
    assign rdmem = M_pre.rm;
    assign rdmem_m = M.rm;
    assign {e_hi,e_lo,m_hi,m_lo} = {M_pre.hi_w,M_pre.lo_w,M.hi_w,M.lo_w};
    assign regval_elo = M_pre.valB;
    assign regval_mlo = W_pre.valB;
    // assign dresp_data = W_pre.valA;
    //module
    fetch fetch_c(.*);
    decode decode_c(.*);
    execute execute_c(.*);
    memory memory_c(.*);
    write_back write_back_c(.*);
    regfile reg_c(.*);
    hilo hilo_c(.*);
    //
    // assign F_pre.pc = F_st?F.pc:(ifj?pc_decode:pc_fetch);
    assign F_pre.pc = ifj?pc_decode:pc_fetch;
    // assign ireq.addr = F_pre.pc; lab1
    // assign ireq.valid = ~(F_pre.pc[0:0]|F_pre.pc[1:1]);
    //control
    always_comb begin
        F_st='0;D_st='0;D_bb='0;E_bb='0;EM_st='0;M_bb='0;W_bb='0;
        if (pcf1==1'b1||pcf2==1'b1) begin
            F_st='1;D_st='1;E_bb='1;
        end
        if (pcf3==1'b1||pcf4==1'b1) begin
            F_st='1;D_st='1;EM_st='1;W_bb='1;
        end
    end
    always_ff @(posedge clk) begin
        if (resetn) begin
        // AHA!
            if (F_st!=1'b1) begin
                F<=F_pre;
            end
            if(D_st!=1'b1) begin
                if ( D_bb==1'b1 ) begin
                    D<='0;
                end else begin
                    D<=D_pre;
                end
            end
            if(EM_st!= 1'b1) begin
                if (E_bb==1'b1) begin
                    E<='0;
                end else begin
                    E<=E_pre;
                end
                if (M_bb==1'b1) begin
                    M<='0;
                end else begin
                    M<=M_pre;
                end
            end
            if (W_bb==1'b1) begin
                W<='0;
            end else begin
                W<=W_pre;
            end
        end else begin
        // reset
        // NOTE: if resetn is X, it will be evaluated to false.
        F<=32'hbfc00000;
        D<='0;
        E<='0;
        M<='0;
        W<='0;
        end
    end
    

    // remove following lines when you start
    //assign ireq = '0;
    //assign dreq = '0;
    //`UNUSED_OK({iresp, dresp});
endmodule
