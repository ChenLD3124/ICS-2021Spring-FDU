`include "pipeline.svh"
module tlb(
	input logic clk, resetn,
	// addr
	input logic[7:0] asid_i,asid_d,
	input word_t inst_vaddr, data_vaddr,
	output word_t inst_paddr_tlb, data_paddr_tlb,// ??
	output logic i_invalid, d_invalid, 
	output logic i_dirty, d_dirty,
	output logic i_hit, d_hit,
	output logic [2:0] d_cache_flag,i_cache_flag
	// TLBP
	input cp0_entryhi_t entryhi,
	output cp0_index_t index
    );
	tlb_table_t tlb_table;
	assign tlbrd = tlb_table[tlbra];
	for (genvar i=0; i<TLB_ENTRIES; i++) begin
	    always_ff @(posedge clk) begin
		if (~resetn) begin
		    tlb_table[i] <= '0;
		end else if (tlbw.valid && tlbw.addr == i) begin
		    tlb_table[i] <= tlbw.data;
		end
	    end
	end
    
	tlblut_resp_t i_resp, d_resp, tlbp_resp;
	assign inst_paddr_tlb = i_resp.paddr;
	assign data_paddr_tlb = d_resp.paddr;
	assign index.P = ~tlbp_resp.hit;
	assign index.index = tlbp_resp.tlb_addr;
	assign index.zero = '0;
	tlb_lut ilut(.tlb_table,
		     .vaddr(inst_vaddr),
		     .asid(asid_i),
		     .tlblut_resp(i_resp));
	tlb_lut dlut(.tlb_table,
		     .vaddr(data_vaddr),
		     .asid(asid_d),
		     .tlblut_resp(d_resp));
	tlb_lut tlbp_lut(.tlb_table,
			 .vaddr(entryhi),
			 .asid,
			 .tlblut_resp(tlbp_resp));
	assign i_invalid= ~i_resp.valid;
	assign d_invalid= ~d_resp.valid;
	assign i_dirty = i_resp.dirty;
	assign d_dirty = d_resp.dirty;
	assign i_hit = i_resp.hit;
	assign d_hit = d_resp.hit;
	assign d_cache_flag = d_resp.cache_flag;
endmodule