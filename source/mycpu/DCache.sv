`include "common.svh"

module DCache (
    input logic clk, resetn,

    input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  dcreq,
    input  cbus_resp_t dcresp
);
    /**
     * TODO (Lab3) your code here :)
     */
    typedef enum i2 { 
        IDLE,
        FETCH,
        READY,
        FLUSH
    } state_t;
    typedef i2 offset_t;
    state_t state;
    offset_t offset,start;
    dbus_req_t req;
    assign start = dreq.addr[3:2];
    struct packed {
        strobe_t strobe;
        word_t wdata;
    } ram;
    logic [3:0][3:0] ram_en;
    logic [3:0][1:0] cp,cp_nxt;
    i2 csn;
    word_t [3:0][3:0] ram_rdata;
    
    typedef struct packed {
        logic valid,dirty,now;
        logic [25:0] index;
    } cache_line;
    cache_line [3:0][3:0] ca,ca_nxt;
    //cache set number
    assign csn = req.addr[5:4];
    // DBus driver
    assign dresp.addr_ok = state == IDLE;
    assign dresp.data_ok = state == READY;
    assign dresp.data    = ram_rdata[csn][hit_num_r];
    // CBus driver
    assign dcreq.valid    = state == FETCH || state == FLUSH;
    assign dcreq.is_write = state == FLUSH;
    assign dcreq.size     = MSIZE4;
    assign dcreq.addr     = req.addr;
    assign dcreq.strobe   = 4'b1111;
    assign dcreq.data     = ram_rdata[csn][hit_num_r];
    assign dcreq.len      = MLEN4;
    logic hit,dirt;
    logic [1:0] hit_num,hit_num_r;
    for (genvar i = 0; i < 16; i++) begin
        LUTRAM #(.NUM_BYTES(16)) ram_line(
            .clk(clk), .en(ram_en[i[3:2]][i[1:0]]),
            .addr(offset),
            .strobe(ram.strobe),
            .wdata(ram.wdata),
            .rdata(ram_rdata[i[3:2]][i[1:0]])
        );
    end
    always_comb begin
        hit='0;ram_en='0;hit_num='0;dirt='0;
        ca_nxt=ca;cp_nxt=cp;
        unique case (state)
            IDLE:begin
                if (dreq.valid) begin
                    for (int i=0; i<4; ++i) begin
                        if(ca[dreq.addr[5:4]][i].valid&&ca[dreq.addr[5:4]][i].index==dreq.addr[31:6])begin
                            hit='1;hit_num=i[1:0];
                            ca_nxt[dreq.addr[5:4]][i].now='1;
                        end
                    end
                    if(hit==1'b0)begin
                        for (int i=0; i<5; ++i) begin
                            /* verilator lint_off WIDTH */
                            if(ca_nxt[dreq.addr[5:4]][i[1:0]+cp[dreq.addr[5:4]]].now)begin
                                ca_nxt[dreq.addr[5:4]][i[1:0]+cp[dreq.addr[5:4]]].now='0;
                            end
                            /* verilator lint_off WIDTH */
                            else begin
                                hit_num=i[1:0]+cp[dreq.addr[5:4]];
                                cp_nxt[dreq.addr[5:4]]=i2'(hit_num+1);
                                break;
                            end
                        end
                        dirt=ca[dreq.addr[5:4]][hit_num].dirty;
                    end
                end
                    
            end
            READY:begin
                ram_en[csn][hit_num_r]='1;
                ram.strobe=req.strobe;
                ram.wdata=req.data;
                if(ram.strobe!=4'b0000)begin
                    ca_nxt[csn][hit_num_r].dirty='1;
                    ca_nxt[csn][hit_num_r].now='1;
                end 
            end
            FETCH:begin
                ram_en[csn][hit_num_r]='1;
                ram.strobe = 4'b1111;
                ram.wdata  = dcresp.data;
                ca_nxt[csn][hit_num_r].dirty='0;
                ca_nxt[csn][hit_num_r].valid='1;
                ca_nxt[csn][hit_num_r].now='1;
                ca_nxt[csn][hit_num_r].index=req.addr[31:6];
            end
            FLUSH:begin
                if(dcresp.ready&&dcresp.last) ca_nxt[csn][hit_num_r].dirty='0;
            end
        endcase
    end
    always_ff @(posedge clk) begin
        if(resetn) begin
            ca<=ca_nxt;
            cp<=cp_nxt;
            unique case (state)
                IDLE:begin
                    if (dreq.valid) begin
                        if(hit) state<=READY;
                        else if(dirt) state<=FLUSH;
                        else state<=FETCH;
                        req<=dreq;
                        offset<=start;
                        hit_num_r<=hit_num;
                    end
                    
                end
                READY:begin
                    state<=IDLE;
                end
                FETCH:begin
                    if (dcresp.ready) begin
                        state  <= dcresp.last ? READY : FETCH;
                        offset <= offset + 1;
                    end
                end
                FLUSH:begin
                    if (dcresp.ready) begin
                        state  <= dcresp.last ? FETCH : FLUSH;
                        offset <= offset + 1;
                    end
                end
            endcase
        end
        else begin
            ca<='0;
            cp<='0;
            state <= IDLE;
            {req, offset} <= '0;
        end
    end
    // remove following lines when you start
    // assign {dresp, dcreq} = '0;
    // `UNUSED_OK({clk, resetn, dreq, dcresp});
endmodule
