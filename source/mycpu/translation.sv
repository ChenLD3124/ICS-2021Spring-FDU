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
	assign i_mapped = ~i_req.vaddr[31] || (i_req.vaddr[31:30] == 2'b11);
	assign d_mapped = ~d_req.vaddr[31] || (d_req.vaddr[31:30] == 2'b11);
	word_t inst_paddr_tlb, data_paddr_tlb, inst_paddr_direct, data_paddr_direct;
	assign i_resp.paddr = i_mapped ? inst_paddr_tlb: inst_paddr_direct;
	assign d_resp.paddr = d_mapped ? data_paddr_tlb: data_paddr_direct;
	logic d_uncached,i_uncached;
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
	tlb tlb(
	    .clk, .resetn,
	    .asid_i(asid_i),
		.asid_d(asid_d),
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