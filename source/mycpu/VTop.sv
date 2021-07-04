`include "access.svh"
`include "common.svh"

module VTop (
    input logic clk, resetn,

    output cbus_req_t  oreq,
    input  cbus_resp_t oresp,

    input i6 ext_int
);
    `include "bus_decl"

    ibus_req_t  ireq;
    ibus_resp_t iresp,ir1,ir2;
    dbus_req_t  dreq;
    dbus_resp_t dresp,dr1,dr2;
    cbus_req_t  icreq,  dcreq,icreq2,  dcreq2,ic2,dc2;
    cbus_resp_t icresp, dcresp,icresp2, dcresp2;

    cbus_req_t vreq;
    i32 paddr;
    logic nocache_i,nocache_d;
    assign nocache_i = (ireq.addr[31:28]==4'b1010)||(ireq.addr[31:28]==4'b1011);
    assign nocache_d = (dreq.addr[31:28]==4'b1010)||(dreq.addr[31:28]==4'b1011);
    assign ic2 = nocache_i?icreq2:'0;
    assign dc2 = nocache_d?dcreq2:'0;
    MyCore core(.*);
    ICache icvt(.iresp(ir1),.*);
    DCache #(.SET_NUM(16),.SET_BIT(4),.LINE_NUM(16),.LINE_BIT(4)) dcvt(.dresp(dr1),.*);
    IBusToCBus icvt2(.icreq(icreq2),.icresp(icresp2),.iresp(ir2),.*);
    DBusToCBus dcvt2(.dcreq(dcreq2),.dcresp(dcresp2),.dresp(dr2),.*);
    assign iresp = nocache_i?ir2:ir1;
    assign dresp = nocache_d?dr2:dr1;
    /**
     * TODO (Lab2) replace mux with your own arbiter :)
     */
    // CBusArbiter
    MyArbiter #(.NUM_INPUTS(4)) mux(
        .ireqs({icreq,ic2, dcreq,dc2}),
        .iresps({icresp,icresp2, dcresp,dcresp2}),
        .oreq(vreq),
        .*
    );

    /**
     * TODO (optional) add address translation for oreq.addr :)
     */
    memtrans transinst(.vaddr(vreq.addr),.paddr(paddr));
    always_comb begin
        oreq=vreq;
        oreq.addr=paddr;
    end
    `UNUSED_OK({ext_int});
endmodule
