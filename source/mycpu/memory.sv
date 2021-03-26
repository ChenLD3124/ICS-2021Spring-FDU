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
    int tmp;
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
        W_pre='0;tmp='0;
        W_pre.pc=M.pc;
        if(M.rm) begin
            dreq.addr=M.valA;
            W_pre.regw=M.regw;
            // W_pre.rm='1;
            W_pre.wen='1;
            unique case (M.OP)
              OP_LW:begin
                dreq.size=MSIZE4;
                W_pre.valA=dresp.data;
              end
              OP_LH,OP_LHU:begin
                dreq.size=MSIZE2;
                tmp=int'(M.valA[1:1])<<4;
                W_pre.valA=(32'hffff<<tmp)&dresp.data;
                if(M.OP==OP_LHU)begin
                  W_pre.valA=signed'((W_pre.valA)<<(16-tmp))>>>(16-tmp);
                end
              end
              OP_LB,OP_LBU:begin
                dreq.size=MSIZE1;
                tmp=int'(M.valA[1:0])<<3;
                W_pre.valA=(32'hff<<tmp)&dresp.data;
                if(M.OP==OP_LBU)begin
                  W_pre.valA=signed'(W_pre.valA<<(24-tmp))>>>(24-tmp);
                end
              end
              default:;
            endcase
            
        end else if(M.wm)begin
            dreq.addr=M.valA;
            unique case (M.OP)
              OP_SB:begin
                dreq.size=MSIZE1;
                dreq.strobe=4'h1<<M.valA[1:0];
                dreq.data=M.valB<<(int'(M.valA[1:0])<<3);
              end
              OP_SW:begin
                dreq.size=MSIZE4;
                dreq.strobe=4'hf;
                dreq.data=M.valB;
              end
              OP_SH:begin
                dreq.size=MSIZE2;
                dreq.strobe=4'h3<<M.valA[1:0];
                dreq.data=M.valB<<(int'(M.valA[1:0])<<3);
              end
            endcase
            
        end else begin
            W_pre.regw=M.regw;
            W_pre.valA=M.valA;
            if (W_pre.regw!=5'b0) begin
                W_pre.wen='1;
            end
        end
    end
endmodule