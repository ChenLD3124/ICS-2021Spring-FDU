`include "pipeline.svh"
module tlb_lut (
    input tlb_table_t tlb_table,  // global in hardware
    input word_t vaddr,
    input logic [7:0] asid,
    output tlblut_resp_t tlblut_resp
);
    logic [TLB_ENTRIES-1:0] hit_mask;
    tlb_addr_t hit_addr;

    for (genvar i=0; i<TLB_ENTRIES; i++) begin
        assign hit_mask[i] = (tlb_table[i].vpn2 == vaddr[31:13]) &&
                             (tlb_table[i].asid == asid || tlb_table[i].G);
                                /* 当前进程的表项 */          /* 全局表项 */
    end

    always_comb begin
        hit_addr = '0;
        for (int i = TLB_ENTRIES - 1; i >= 0; i--) begin
            if (hit_mask[i]) begin
                hit_addr = i;
            end
        end
    end

    assign tlblut_resp.paddr = {
        vaddr[12] ? tlb_table[hit_addr].pfn1 : tlb_table[hit_addr].pfn0,
        vaddr[11:0]
    };
    assign tlblut_resp.tlb_addr = hit_addr;
	assign tlblut_resp.hit = |hit_mask;
	assign tlblut_resp.dirty = vaddr[12] ? tlb_table[hit_addr].D1 : tlb_table[hit_addr].D0;
	assign tlblut_resp.valid = vaddr[12] ? tlb_table[hit_addr].V1 : tlb_table[hit_addr].V0;
	assign tlblut_resp.cache_flag = vaddr[12] ? tlb_table[hit_addr].C1 : tlb_table[hit_addr].C0;
endmodule