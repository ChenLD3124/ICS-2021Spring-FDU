`include "pipeline.svh"
module memory(
    input logic clk,
    input M_type M,
    output W_type W_pre,
    input dbus_resp_t dresp,
    output dbus_req_t dreq,
    output logic pcf3
);
    logic valid,valid_nxt;
    assign pcf3 = (M.rm|M.wm)?~dresp.data_ok:'0;
    always_ff @(posedge clk) begin
        if (pcf3==1'b0) begin
          valid<='1;
        end
        else if(dresp.addr_ok==1'b1) begin
          valid<='0;
        end
        else begin
          valid<=valid_nxt;
        end
      end
    assign valid_nxt = valid;
    always_comb begin
        dreq='0;
        dreq.valid = (M.rm|M.wm)?valid:'0;
        W_pre='0;
        W_pre.pc=M.pc;
        if(M.rm) begin
            // dreq.valid=1'b1;
            dreq.addr=M.valA;
            dreq.size=MSIZE4;
            W_pre.regw=M.regw;
            W_pre.rm='1;
            W_pre.wen='1;
            W_pre.valA=dresp.data;
        end else if(M.wm)begin
            // dreq.valid=1'b1;
            dreq.addr=M.valA;
            dreq.size=MSIZE4;
            dreq.strobe=4'hf;
            dreq.data=M.valB;
        end else begin
            W_pre.regw=M.regw;
            W_pre.valA=M.valA;
            if (W_pre.regw!=5'b0) begin
                W_pre.wen='1;
            end
        end
    end
endmodule