`include "access.svh"
`include "common.svh"

module VTop (
    input logic clk, resetn,

    output cbus_req_t  oreq,
    input  cbus_resp_t oresp,

    input i6 ext_int
);
    `include "bus_decl"

    ibus_req_t  ireq,ireq_p;
    ibus_resp_t iresp,ir1,ir2;
    dbus_req_t  dreq,dreq_p;
    /* verilator lint_off UNOPTFLAT */
    dbus_resp_t dresp,dr1,dr2;
    /* verilator lint_on UNOPTFLAT */
    cbus_req_t  icreq,  dcreq,icreq2,  dcreq2,icreq1,dcreq1;
    cbus_resp_t icresp, dcresp;

    // cbus_req_t vreq;
    i32 ipaddr,dpaddr;
    logic nocache_i,nocache_d;
    assign nocache_i = (ireq.addr[31:28]==4'b1010)||(ireq.addr[31:28]==4'b1011);
    assign nocache_d = (dreq.addr[31:28]==4'b1010)||(dreq.addr[31:28]==4'b1011);
    assign icreq = nocache_i?icreq2:icreq1;
    assign dcreq = nocache_d?dcreq2:dcreq1;
    MyCore core(.*);
    ICache icvt(.iresp(ir1),.icreq(icreq1),.ireq(ireq_p),.nocache(nocache_i),.*);
    DCache #(.SET_NUM(16),.SET_BIT(4),.LINE_NUM(16),.LINE_BIT(4)) dcvt(.dresp(dr1),.dcreq(dcreq1),.dreq(dreq_p),.nocache(nocache_d),.*);
    IBusToCBus icvt2(.icreq(icreq2),.icresp(icresp),.iresp(ir2),.ireq(ireq_p),.*);
    DBusToCBus dcvt2(.dcreq(dcreq2),.dcresp(dcresp),.dresp(dr2),.dreq(dreq_p),.*);
    assign iresp = nocache_i?ir2:ir1;
    assign dresp = nocache_d?dr2:dr1;
    /**
     * TODO (Lab2) replace mux with your own arbiter :)
     */
    // CBusArbiter
    MyArbiter mux(
        .ireqs({icreq,dcreq}),
        .iresps({icresp,dcresp}),
        .oreq,
        .*
    );

    /**
     * TODO (optional) add address translation for oreq.addr :)
     */
    memtrans transinsti(.vaddr(ireq.addr),.paddr(ipaddr));
    always_comb begin
        ireq_p=ireq;
        ireq_p.addr=ipaddr;
    end
    memtrans transinstd(.vaddr(dreq.addr),.paddr(dpaddr));
    always_comb begin
        dreq_p=dreq;
        dreq_p.addr=dpaddr;
    end
    // `UNUSED_OK({ext_int});
endmodule
