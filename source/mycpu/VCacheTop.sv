`include "access.svh"
`include "common.svh"

module VCacheTop (
    input logic clk, resetn,

    input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);
    `include "bus_decl"

    cbus_req_t  dcreq;
    cbus_resp_t dcresp;

    assign creq = dcreq;
    assign dcresp = cresp;
    DCache top(.*);

    /**
     * TODO (Lab3, optional) expose internal memory to simulator
     *
     * NOTE: it will slow down FST tracing significantly, especially
     *       if your cache is large, you may want to speed up by adding
     *       "// verilator tracing_off" before the declaration of
     *       the variable mem.
     */

    /**
     * the following is an example. Suppose that you used LUTRAM and
     * your cache contains only four cache lines, each of which consists of
     * 16 consecutive words in memory.
     *
     * later you can access the variable mem from C++ via VCacheTop->mem.
     * it will possibly become a 1d array of uint32_t.
     */
    typedef word_t [3:0] cache_line_t;
    
    
    //
    /* verilator tracing_off */
    cache_line_t [3:0][3:0] mem /* verilator public_flat_rd */;
    word_t [3:0][3:0][3:0] can/* verilator public_flat_rd */;
    word_t [3:0] cpn/* verilator public_flat_rd */;
    /* verilator tracing_on */
    //
    for (genvar i = 0; i < 16; i++) begin
        assign mem[i[3:2]][i[1:0]] = top.cl[i].ram_line.behavioral.mem;
        assign can[i[3:2]][i[1:0]][0] = {31'b0,top.ca[i[3:2]][i[1:0]].valid};
        assign can[i[3:2]][i[1:0]][1] = {31'b0,top.ca[i[3:2]][i[1:0]].dirty};
        assign can[i[3:2]][i[1:0]][2] = {31'b0,top.ca[i[3:2]][i[1:0]].now};
        assign can[i[3:2]][i[1:0]][3] = {top.ca[i[3:2]][i[1:0]].index,6'b0};
    end
    for (genvar i = 0; i < 4; i++) begin
        assign cpn[i] = {30'b0,top.cp[i]};
    end
    
endmodule
