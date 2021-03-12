`include "pipeline.svh"
module memory(
    input M_type M,
    output W_type W_pre,
    input dbus_resp_t dresp,
    output dbus_req_t dreq 
);
    always_comb begin
        dreq='0;
        W_pre='0;
        W_pre.pc=M.pc;
        if(M.rm==1'b1) begin
            dreq.valid=1'b1;
            dreq.addr=M.valA;
            dreq.size=MSIZE4;
            W_pre.regw=M.regt;
            W_pre.rm='1;
            W_pre.wen='1;
        end else if(M.wm==1'b1)begin
            dreq.valid=1'b1;
            dreq.addr=M.valA;
            dreq.size=MSIZE4;
            dreq.strobe=4'hf;
            dreq.data=M.valB;
        end else begin
            W_pre.regw=M.regt;
            W_pre.valA=M.valA;
            if (W_pre.regw!=5'b0) begin
                W_pre.wen='1;
            end
        end
    end
endmodule