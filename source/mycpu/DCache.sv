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
    typedef i4 offset_t;
    state_t state;
    offset_t offset,start;
    dbus_req_t req;
    assign start = dreq.addr[3:2];
    struct packed {
        strobe_t strobe;
        word_t wdata;
    } ram;
    logic [1:0][1:0] ram_en,cp,cp_nxt;
    i2 csn;
    word_t [1:0][1:0] ram_rdata;
    
    typedef struct packed {
        logic valid,dirty,now;
        logic [25:0] index;
    } cache_line;
    cache_line [1:0][1:0] ca,ca_nxt;
    i2 [1:0] found;
    //cache set number
    assign csn = req.addr[5:4];
    // DBus driver
    assign dresp.addr_ok = state == IDLE;
    assign dresp.data_ok = state == READY;
    assign dresp.data    = ram_rdata[csn][hit_num_r];
    // CBus driver
    assign creq.valid    = state == FETCH || state == FLUSH;
    assign creq.is_write = state == FLUSH;
    assign creq.size     = MSIZE4;
    assign creq.addr     = req.addr;
    assign creq.strobe   = 4'b1111;
    assign creq.data     = ram_rdata[csn][hit_num_r];
    assign creq.len      = MLEN4;
    logic hit,dirt;
    logic [1:0] hit_num,hit_num_r;
    for (genvar i = 0; i < 16; i++) begin
        LUTRAM ram_line(
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
                for (int i=0; i<4; ++i) begin
                    if(ca[dreq.addr[3:2]][i].valid&&ca[dreq.addr[3:2]][i].index==dreq[31:6])begin
                        hit='1;hit_num=i;
                        ca_nxt[dreq.addr[3:2]][i].now='1;
                    end
                end
                if(hit=1'b0)begin
                    for (int i=0; i<5; ++i) begin
                        if(ca_nxt[dreq.addr[3:2]][i2'(i+cp[dreq[3:2]])].now)begin
                            ca_nxt[dreq.addr[3:2]][i2'(i+cp[dreq[3:2]])].now='0;
                        end
                        else begin
                            hit_num=i+cp[dreq[3:2]];
                            cp_nxt[dreq[3:2]]=hit_num+1;
                            break;
                        end
                    end
                    dirt=ca[dreq.addr[3:2]][hit_num].dirty;
                end
            end
            READY:begin
                ram_en[csn][hit_num_r]='1;
                ram.strobe=req.strobe;
                ram.wdata=req.data;
                if(|ram.strobe)begin
                    ca_nxt[csn][hit_num_r].dirty='1;
                    ca_nxt[csn][hit_num_r].now='1;
                end 
            end
            FETCH:begin
                ram_en[csn][hit_num_r]='1;
                ram.strobe = 4'b1111;
                ram.wdata  = cresp.data;
                ca_nxt[csn][hit_num_r].dirty='0;
                ca_nxt[csn][hit_num_r].valid='1;
                ca_nxt[csn][hit_num_r].now='1;
            end
            FLUSH:begin
                if(cresp.ready&&cresp.last) ca_nxt[csn][hit_num_r].dirty='0;
            end
        endcase
    end
    always_ff @(posedge clk) begin
        if(resetn) begin
            ca<=ca_nxt;
            cp<=cp_nxt;
            unique case (state)
                IDLE:begin
                    if(hit) state<=READY;
                    else if(dirt) state<=FLUSH;
                    else state<=FETCH;
                    req<=dreq;
                    offset<=start;
                    hit_num_r<=hit_num;
                end
                READY:begin
                    state<=IDLE;
                end
                FETCH:begin
                    if (cresp.ready) begin
                        state  <= cresp.last ? READY : FETCH;
                        offset <= offset + 1;
                    end
                end
                FLUSH:begin
                    if (cresp.ready) begin
                        state  <= cresp.last ? FETCH : FLUSH;
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
