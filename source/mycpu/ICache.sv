`include "common.svh"

module ICache (
    input logic clk, resetn,

    input  ibus_req_t  ireq,
    output ibus_resp_t iresp,
    output cbus_req_t  icreq,
    input  cbus_resp_t icresp
);
    // simply use DCache as ICache
    DCache #(.SET_NUM(16),.SET_BIT(4),.LINE_NUM(16),.LINE_BIT(4)) proxy(
        .dreq(`IREQ_TO_DREQ(ireq)),
        .dresp(iresp),
        .dcreq(icreq),
        .dcresp(icresp),
        .*
    );
endmodule
