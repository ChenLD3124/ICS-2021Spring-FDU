`include "common.svh"

module MyArbiter #(
    parameter int NUM_INPUTS = 2,

    localparam int MAX_INDEX = NUM_INPUTS - 1
) (
    input logic resetn,clk,
    input  cbus_req_t  [MAX_INDEX:0] ireqs,
    output cbus_resp_t [MAX_INDEX:0] iresps,
    output cbus_req_t  oreq,
    input  cbus_resp_t oresp
);
    /**
     * TODO (Lab2) your code here :)
     */
    logic lock,lock_nxt;
    i2 sel,sel_l;
    cbus_req_t sel_req,sel_req_l;
    assign oreq = sel_req;
    always_comb begin
        iresps='0;
        if(lock==1'b1)begin
            sel_req=sel_req_l;
            sel=sel_l;
            iresps[sel]=oresp;
        end else begin
            sel_req='0;sel='1;
            for(int i=0;i<NUM_INPUTS;++i)begin
                if(ireqs[i[1:0]].valid==1'b1)begin
                    sel_req=ireqs[i[1:0]];
                    sel=i[1:0];
                    break;
                end
            end
        end
    end
    always_ff @(posedge clk) begin
        if(~resetn)begin lock<='0;sel_l<='1;sel_req_l<=0;end
        else begin
            sel_l<=sel;
            sel_req_l<=sel_req;
            if(oresp.last==1'b1)begin
                lock<='0;
            end else if (oreq.valid==1'b1) begin
                lock<='1;
            end else begin
                lock<=lock_nxt;
            end
        end
    end
    assign lock_nxt = lock;
    // remove following lines when you start
    // assign iresps = '0;
    // assign oreq = '0;
    // `UNUSED_OK({ireqs, oresp});
endmodule
