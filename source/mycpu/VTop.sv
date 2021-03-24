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
    ibus_resp_t iresp;
    dbus_req_t  dreq;
    dbus_resp_t dresp;
    cbus_req_t  icreq,  dcreq;
    cbus_resp_t icresp, dcresp;

    cbus_req_t vreq;
    i32 paddr;

    MyCore core(.*);
    IBusToCBus icvt(.*);
    DBusToCBus dcvt(.*);

    /**
     * TODO (Lab2) replace mux with your own arbiter :)
     */
    CBusArbiter mux(
        .ireqs({icreq, dcreq}),
        .iresps({icresp, dcresp}),
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
