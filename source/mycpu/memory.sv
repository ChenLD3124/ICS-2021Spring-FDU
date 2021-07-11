`include "pipeline.svh"
module memory(
    input logic clk,
    input M_type M,
    output W_type W_pre,
    input dbus_resp_t dresp,
    output dbus_req_t dreq,
    output logic pcf3,
    output logic exp,cp0_wen,cp0_badwen,
    output i5 cp0_regw,excode,
    output i32 cp0_wdata,cp0_badvaddr
);
    logic valid,valid_nxt,M_ADEL,M_ADES;
    int tmp;
    assign pcf3 = exp?'0:((M.rm|M.wm)?~dresp.data_ok:'0);
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
      M_ADEL='0;M_ADES='0;
      if ((M.OP==OP_LW||M.OP==OP_LL)&&M.rm&&(M.valA[0]|M.valA[1])) begin
        M_ADEL='1;
      end
      else if ((M.OP==OP_LH||M.OP==OP_LHU)&&M.rm&&M.valA[0]) begin
        M_ADEL='1;
      end
      else if ((M.OP==OP_SW||M.OP==OP_SC)&&M.wm&&(M.valA[0]|M.valA[1])) begin
        M_ADES='1;
      end
      else if (M.OP==OP_SH&&M.wm&&M.valA[0]) begin
        M_ADES='1;
      end
    end
    assign exp = M.exp[11:0]!='0;
    always_comb begin
      excode='0;
      cp0_badwen='0;cp0_badvaddr='0;
      if (M.exp.INT) begin
        excode=INT;
      end
      else if (M.exp.ADEL) begin
        excode=ADEL;cp0_badwen='1;
        cp0_badvaddr=M.pc;
      end
      else if (M.exp.SYS) begin
        excode=SYS;
      end
      else if (M.exp.BP) begin
        excode=BP;
      end
      else if (M.exp.RI) begin
        excode=RI;
      end
      else if (M.exp.OV) begin
        excode=OV;
      end
      else if (M.exp.TR) begin
        excode=TR;
      end
      else if (M_ADEL) begin
        excode=ADEL;cp0_badwen='1;
        cp0_badvaddr=M.valA;
      end
      else if (M_ADES) begin
        excode=ADES;cp0_badwen='1;
        cp0_badvaddr=M.valA;
      end
    end
    always_comb begin
      cp0_wen='0;cp0_regw='0;
      if (exp=='0&&M.exp.wen) begin
        cp0_regw=M.exp.regw;
        cp0_wen='1;
        cp0_wdata=M.valA;
      end
    end
    always_comb begin
        dreq='0;
        W_pre='0;tmp='0;
        W_pre.pc=M.pc;
        // W_pre.t=M.t;
        {W_pre.hi_w,W_pre.lo_w}={M.hi_w,M.lo_w};
        if(exp==1'b0) begin
          dreq.valid = (M.rm|M.wm)?valid:'0;
          if(M.rm) begin
              dreq.addr=M.valA;
              W_pre.regw=M.regw;
              // W_pre.rm='1;
              if (M.regw!=5'b0) begin
                W_pre.wen='1;
              end 
              unique case (M.OP)
                OP_LW,OP_LL:begin
                  dreq.size=MSIZE4;
                  W_pre.valA=dresp.data;
                end
                OP_LH,OP_LHU:begin
                  dreq.size=MSIZE2;
                  tmp=int'(M.valA[1:1])<<4;
                  W_pre.valA=(dresp.data>>tmp)&32'hffff;
                  if(M.OP==OP_LH)begin
                    W_pre.valA={{16{W_pre.valA[15]}},W_pre.valA[15:0]};//signed'(W_pre.valA<<16)>>>16;
                  end
                end
                OP_LB,OP_LBU:begin
                  dreq.size=MSIZE1;
                  tmp=int'(M.valA[1:0])<<3;
                  W_pre.valA=(dresp.data>>tmp)&32'hff;
                  if(M.OP==OP_LB)begin
                    W_pre.valA={{24{W_pre.valA[7]}},W_pre.valA[7:0]};//signed'(W_pre.valA<<24)>>>24;
                  end
                end
                OP_LWL:begin
                  dreq.size=MSIZE4;
                  tmp=int'(3-M.valA[1:0])<<3;
                  W_pre.valA=dresp.data<<tmp;
                  W_pre.valA=W_pre.valA|(M.valB&(~(32'hff000000>>>tmp)));
                end
                OP_LWR:begin
                  dreq.size=MSIZE4;
                  tmp=int'(M.valA[1:0])<<3;
                  W_pre.valA=dresp.data>>tmp;
                  W_pre.valA=(M.valB&((32'hff000000>>>tmp)<<8))|W_pre.valA;
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
                OP_SW,OP_SC:begin
                  dreq.size=MSIZE4;
                  dreq.strobe=4'hf;
                  dreq.data=M.valB;
                end
                OP_SH:begin
                  dreq.size=MSIZE2;
                  dreq.strobe=4'h3<<M.valA[1:0];
                  dreq.data=M.valB<<(int'(M.valA[1:0])<<3);
                end
                OP_SWL:begin
                  dreq.size=MSIZE4;
                  tmp=3-int'(M.valA[1:0]);
                  dreq.strobe=4'hf>>tmp;
                  dreq.data=M.valB>>(tmp<<3);
                end
                OP_SWR:begin
                  dreq.size=MSIZE4;
                  tmp=int'(M.valA[1:0]);
                  dreq.strobe=4'hf<<tmp;
                  dreq.data=M.valB<<(tmp<<3);
                end
                default:;
              endcase

          end else begin
              W_pre.regw=M.regw;
              W_pre.valA=M.valA;
              W_pre.valB=M.valB;
              if (W_pre.regw!=5'b0) begin
                  W_pre.wen='1;
              end
          end
        end
    end
endmodule