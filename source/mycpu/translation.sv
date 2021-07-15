`include "pipeline"
module translation(
	input logic clk, resetn,
	// address translation requests
	input logic k0_uncached, is_store,
	input  tu_addr_req_t  i_req,  d_req,
	output tu_addr_resp_t i_resp, d_resp,
    
	// TU interactions
	input  tu_op_req_t  op_req,
	output tu_op_resp_t op_resp
    );
    
	logic i_mapped, d_mapped;
	logic i_invalid, d_invalid;
	logic i_dirty, d_dirty;
	logic i_hit, d_hit;
	tlb_entry_t tlbrd;
	assign i_mapped = ~i_req.vaddr[31] || (i_req.vaddr[31:30] == 2'b11);
	assign d_mapped = ~d_req.vaddr[31] || (d_req.vaddr[31:30] == 2'b11);
	word_t inst_paddr_tlb, data_paddr_tlb, inst_paddr_direct, data_paddr_direct;
	assign i_resp.paddr = i_mapped ? inst_paddr_tlb: inst_paddr_direct;
	assign d_resp.paddr = d_mapped ? data_paddr_tlb: data_paddr_direct;
	logic d_uncached,i_uncached;
	assign op_resp.i_tlb_invalid = i_mapped & i_invalid & i_req.req;
	assign op_resp.i_tlb_modified = '0;
	assign op_resp.d_tlb_invalid = d_mapped & d_invalid& d_req.req;
	assign op_resp.d_tlb_modified = d_mapped & ~d_invalid & ~d_dirty& d_req.req&is_store;
	assign op_resp.i_tlb_refill = i_mapped & ~i_hit & i_req.req;
	assign op_resp.d_tlb_refill = d_mapped & ~d_hit& d_req.req;
	assign op_resp.i_mapped = i_mapped;
	assign op_resp.d_mapped = d_mapped;
	trans_direct i_map_inst(
	    .vaddr(i_req.vaddr),
	    .paddr(inst_paddr_direct),
	    .is_uncached(i_uncached),
	    .k0_uncached
	);
	trans_direct d_map_inst(
	    .vaddr(d_req.vaddr),
	    .paddr(data_paddr_direct),
	    .is_uncached(d_uncached),
	    .k0_uncached
	);
	logic[2:0] d_cache_flag,i_cache_flag;
	assign i_resp.is_uncached = i_uncached||(i_mapped&&i_cache_flag!=3'd3);
	assign d_resp.is_uncached = d_uncached || (d_mapped && d_cache_flag != 3'd3);
	
	assign tlbw.valid = op_req.is_tlbwi;
	assign tlbw.addr = op_req.index.index;
	assign tlbw.data.vpn2 = op_req.entryhi.vpn2;
	assign tlbw.data.asid = op_req.entryhi.asid;
	assign tlbw.data.G = op_req.entrylo0.G & op_req.entrylo1.G;
	assign tlbw.data.pfn0 = op_req.entrylo0.pfn;
	assign tlbw.data.pfn1 = op_req.entrylo1.pfn;
	assign tlbw.data.C0 = op_req.entrylo0.C;
	assign tlbw.data.C1 = op_req.entrylo1.C;
	assign tlbw.data.V0 = op_req.entrylo0.V;
	assign tlbw.data.V1 = op_req.entrylo1.V;
	assign tlbw.data.D0 = op_req.entrylo0.D;
	assign tlbw.data.D1 = op_req.entrylo1.D;

	assign op_resp.entryhi[31:13] = tlbrd.vpn2;
	assign op_resp.entryhi[12:8] = '0;
	assign op_resp.entryhi[7:0] = tlbrd.asid;
	assign op_resp.entrylo0[31:30] = '0;
	assign op_resp.entrylo0[29:6] = tlbrd.pfn0;
	assign op_resp.entrylo0[5:3] = tlbrd.C0;
	assign op_resp.entrylo0[2:2] = tlbrd.D0;
	assign op_resp.entrylo0[1:1] = tlbrd.V0;
	assign op_resp.entrylo0[0:0] = tlbrd.G;
	assign op_resp.entrylo1[31:30]= '0;
	assign op_resp.entrylo1[29:6] = tlbrd.pfn1;
	assign op_resp.entrylo1[5:3]  = tlbrd.C1;
	assign op_resp.entrylo1[2:2]  = tlbrd.D1;
	assign op_resp.entrylo1[1:1]  = tlbrd.V1;
	assign op_resp.entrylo1[0:0]  = tlbrd.G;

	tlb tlb(
	    .clk, .resetn,
	    .asid(op_req.entryhi[7:0]),
	    .inst_vaddr(i_req.vaddr),
	    .data_vaddr(d_req.vaddr),
	    .inst_paddr_tlb,
	    .data_paddr_tlb,
	    .i_invalid, .d_invalid,
	    .i_dirty, .d_dirty,
	    .i_hit, .d_hit,
	    .d_cache_flag,
		.i_cache_flag
	);
	logic __unused_ok = &{1'b0, clk, resetn, op_req, 1'b0};
endmodule