`include "pipeline.svh"
module fetch(
    input F_type F,
    input ibus_resp_t iresp,
    output D_type D_pre,
    // output ibus_req_t ireq,
    output i32 pc_fetch
);
    // assign ireq.addr=F.pc;
    assign D_pre.pc = F.pc;
    assign D_pre.imp=iresp.data;
    // assign ireq.valid=1'b1;
    always_comb begin
      pc_fetch = F.pc+32'b100;  
    end
endmodule