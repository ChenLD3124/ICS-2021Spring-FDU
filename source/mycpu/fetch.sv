`include "pipeline.svh"
module fetch(
    input F_type F,
    input ibus_resp_t iresp,
    output D_type D_pre,
    output ibus_req_t ireq,
    output i32 pc_fetch,
    output logic pcf2,
    input logic clk,
    input logic resetn,
    input logic cp0_t,i_tlb_invalid,i_tlb_refill
);
    logic valid,valid_nxt,int_err;
    assign D_pre.pc = F.pc;
    assign D_pre.imp=int_err?'0:iresp.data;
    assign pc_fetch = F.pc+32'b100;
    assign int_err = F.pc[0]|F.pc[1];
    always_comb begin
      D_pre.exp='0;
      D_pre.exp.ADEL=int_err;
      D_pre.exp.INT=F.cp0_int;
      D_pre.exp.TLBI=i_tlb_invalid;
      D_pre.exp.TLBRI=i_tlb_refill;
      D_pre.exp.t=cp0_t;
    end
    //
    assign ireq.valid=int_err?'0:valid;
    assign ireq.addr = F.pc;
    assign pcf2 =int_err?'0:(~iresp.data_ok);
    always_ff @(posedge clk) begin
    if(resetn) begin
      if (iresp.data_ok==1'b1||int_err) begin
        valid<='1;
      end
      else if(iresp.addr_ok==1'b1) begin
        valid<='0;
      end
      else begin
        valid<=valid_nxt;
      end
    end else begin
      valid<='1;
    end
    end
    assign valid_nxt = valid;
    // assign ireq.addr=F.pc;
endmodule