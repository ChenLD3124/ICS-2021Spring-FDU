`include "pipeline.svh"
module fetch(
    input F_type F,
    input ibus_resp_t iresp,
    output D_type D_pre,
    output ibus_req_t ireq,
    output i32 pc_fetch,
    output logic pcf2,
    input logic clk
);
    logic valid,valid_nxt;
    assign D_pre.pc = F.pc;
    assign D_pre.imp=iresp.data;
    assign pc_fetch = F.pc+32'b100;

    //
    assign ireq.valid=valid;
    assign ireq.addr = F.pc;
    assign pcf2 =~iresp.data_ok;
    always_ff @(posedge clk) begin
      if (iresp.data_ok==1'b1) begin
        valid<='1;
      end
      else if(iresp.addr_ok==1'b1) begin
        valid<='0;
      end
      else begin
        valid<=valid_nxt;
      end
    end
    assign valid_nxt = valid;
    // assign ireq.addr=F.pc;
endmodule