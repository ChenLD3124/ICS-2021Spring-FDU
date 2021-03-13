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
    W_type W,W_pre;
    //wire for link regfile
    creg_addr_t ra1,ra2,wa3;
    logic write_enable;
    word_t wd3,rd1,rd2;
    i32 pc_decode,pc_fetch;
    logic ifj;
    logic F_st,D_st,EM_st;
    logic E_bb,M_bb;
    i5 regw_execute,regw_memory;
    i32 regval_execute,regval_memory;
    logic rdmem,rdmem_m;
    i32 dresp_data;
    // i32 D_imp;
    assign regval_execute = M_pre.valA;
    assign regw_execute = E.regw;
    assign regval_memory = W_pre.valA;
    assign regw_memory = M.regw;
    assign rdmem = M_pre.rm;
    assign rdmem_m = M.rm;
    assign dresp_data = dresp.data;
    assign EM_st = '0;
    assign M_bb = '0;
    // assign D_imp = resetn?iresp.data:'0;
    //module
    fetch fetch_c(.*);
    decode decode_c(.*);
    execute execute_c(.*);
    memory memory_c(.*);
    write_back write_back_c(.*);
    regfile reg_c(.*);
    //
    assign F_pre.pc = F_st?F.pc:(ifj?pc_decode:pc_fetch);
    assign ireq.addr = F_pre.pc;
    assign ireq.valid = ~(F_pre.pc[0:0]|F_pre.pc[1:1]);
    always_ff @(posedge clk) begin
        if (resetn) begin
        // AHA!
        if (F_st!=1'b1) begin
            F<=F_pre;
            // F_pre.pc<=
        end
        if(D_st!=1'b1) begin
            D<=D_pre;
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
            W<=W_pre;
        end else begin
        // reset
        // NOTE: if resetn is X, it will be evaluated to false.
        // F_pre.pc<=32'hbfc00004;
        F<=32'hbfc00000;
        D<='0;//D_pre<='0;
        E<='0;//E_pre<='0;
        M<='0;//M_pre<='0;
        W<='0;//W_pre<='0;
        end
    end
    

    // remove following lines when you start
    // assign ireq = '0;
    // assign dreq = '0;
    // logic _unused_ok = &{iresp, dresp};
endmodule
