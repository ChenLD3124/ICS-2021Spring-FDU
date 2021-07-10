`include "pipeline.svh"
module mmu(
    input logic clk, resetn,
    input ibus_req_t ireq,
    input dbus_req_t dreq,
    output ibus_req_t ireq_p,
    output dbus_req_t dreq_p,
    output nocache_i,nocache_d
);
    tu_addr_req_t  i_req,  d_req;
    tu_addr_resp_t i_resp, d_resp;
    translation translation_inst(
            .clk, .resetn,
            .op_req(tu_op_req), .op_resp(tu_op_resp),
            .k0_uncached(1'b1), .is_store(is_store),
            .i_req, .i_resp,
            .d_req, .d_resp
    );

    assign i_req.vaddr = ireq.addr;
    assign i_req.req = ireq.valid;
    assign d_req.vaddr = dreq.addr;
    assign d_req.req = dreq.valid;

    assign ireq_p.addr = i_resp.paddr;
    assign ireq_p.valid = ireq.valid & ~|{tu_op_resp.i_tlb_invalid,
                                    tu_op_resp.i_tlb_modified,
                                    tu_op_resp.i_tlb_refill};
    
    always_comb begin
        dreq_p = dreq;
        dreq_p.addr = d_resp.paddr;
        dreq_p.valid = dreq.valid & ~|{tu_op_resp.d_tlb_invalid,
                                tu_op_resp.d_tlb_modified,
                                tu_op_resp.d_tlb_refill};
    end
endmodule