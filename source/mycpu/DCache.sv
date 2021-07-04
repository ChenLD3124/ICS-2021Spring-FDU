`include "common.svh"

module DCache #(
    parameter int SET_NUM = 4,
    parameter int SET_BIT = 2,
    parameter int LINE_NUM = 4,
    parameter int LINE_BIT = 2
)(
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
    assign start = dreq.addr[LINE_BIT+1:2];
    struct packed {
        strobe_t strobe;
        word_t wdata;
    } ram;
    logic [SET_NUM-1:0][LINE_NUM-1:0] ram_en;
    logic [SET_NUM-1:0][LINE_BIT-1:0] cp,cp_nxt;
    logic [SET_BIT-1:0] csn,F_offset;
    word_t [SET_NUM-1:0][LINE_NUM-1:0] ram_rdata;
    logic nocache;
    assign nocache=(dreq.addr[31:28]==4'b1010)||(dreq.addr[31:28]==4'b1011);
    typedef struct packed {
        logic valid,dirty,now;
        logic [27-SET_BIT:0] index;
    } cache_line;
    cache_line [LINE_NUM-1:0][SET_NUM-1:0] ca,ca_nxt;
    //cache set number
    assign csn = req.addr[3+SET_BIT:4];
    // DBus driver
    assign dresp.addr_ok = state == IDLE;
    assign dresp.data_ok = state == READY;
    assign dresp.data    = ram_rdata[csn][hit_num_r];
    // CBus driver
    assign dcreq.valid    = state == FETCH || state == FLUSH;
    assign dcreq.is_write = state == FLUSH;
    assign dcreq.size     = MSIZE4;
    assign dcreq.addr     = (state == FLUSH)?{ca[csn][hit_num_r].index,csn,2'b0,2'b0}:{req.addr[31:4],4'b0};
    assign dcreq.strobe   = 4'b1111;
    assign dcreq.data     = ram_rdata[csn][hit_num_r];
    assign dcreq.len      = MLEN4;
    logic hit,dirt;
    // addr_t F_addr;
    typedef logic [LINE_BIT-1:0] hit_t;
    hit_t hit_num,hit_num_r;
    for (genvar i = 0; i < LINE_NUM*SET_NUM; i++) begin:cl
        LUTRAM #(.NUM_BYTES(16)) ram_line(
            .clk(clk), .en(ram_en[i[SET_BIT+LINE_BIT-1:LINE_BIT]][i[LINE_BIT-1:0]]),
            .addr((state==FLUSH||state==FETCH)?F_offset:offset),
            .strobe(ram.strobe),
            .wdata(ram.wdata),
            .rdata(ram_rdata[i[SET_BIT+LINE_BIT-1:LINE_BIT]][i[LINE_BIT-1:0]])
        );
    end
    always_comb begin
        hit='0;ram_en='0;hit_num='0;dirt='0;
        ca_nxt=ca;cp_nxt=cp;
        unique case (state)
            IDLE:begin
                if (dreq.valid&&nocache==1'b0) begin
                    for (int i=0; i<LINE_NUM; ++i) begin
                        if(ca[dreq.addr[3+SET_BIT:4]][i].valid&&ca[dreq.addr[SET_BIT+3:4]][i].index==dreq.addr[31:4+SET_BIT])begin
                            hit='1;hit_num=i[LINE_BIT-1:0];
                            break;
                        end
                    end
                    if(hit==1'b0)begin
                        for (int i=0; i<LINE_NUM+1; ++i) begin
                            hit_num=hit_t'(i[LINE_BIT-1:0]+cp[dreq.addr[3+SET_BIT:4]]);
                            if(ca_nxt[dreq.addr[3+SET_BIT:4]][hit_num].now)begin
                                ca_nxt[dreq.addr[3+SET_BIT:4]][hit_num].now='0;
                            end
                            else begin
                                cp_nxt[dreq.addr[3+SET_BIT:4]]=hit_t'(hit_num+1);
                                break;
                            end
                        end
                        dirt=ca[dreq.addr[3+SET_BIT:4]][hit_num].dirty;
                    end
                end
                    
            end
            READY:begin
                ram_en[csn][hit_num_r]='1;
                ram.strobe=req.strobe;
                ram.wdata=req.data;
                ca_nxt[csn][hit_num_r].now='1;
                if(ram.strobe!=4'b0000)begin
                    ca_nxt[csn][hit_num_r].dirty='1;
                end 
            end
            FETCH:begin
                ram_en[csn][hit_num_r]='1;
                ram.strobe = 4'b1111;
                ram.wdata  = dcresp.data;
                ca_nxt[csn][hit_num_r].dirty='0;
                ca_nxt[csn][hit_num_r].valid='1;
                ca_nxt[csn][hit_num_r].index=req.addr[31:4+SET_BIT];
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
                    if (dreq.valid&&nocache==1'b0) begin
                        if(hit) state<=READY;
                        else if(dirt) state<=FLUSH;
                        else state<=FETCH;
                        // F_addr<={ca[dreq.addr[5:4]][hit_num].index,dreq.addr[5:4],2'b00};
                        req<=dreq;
                        offset<=start;
                        hit_num_r<=hit_num;
                        F_offset<='0;
                    end
                    
                end
                READY:begin
                    state<=IDLE;
                end
                FETCH:begin
                    if (dcresp.ready) begin
                        state  <= dcresp.last ? READY : FETCH;
                        F_offset <= F_offset + 1;
                    end
                end
                FLUSH:begin
                    if (dcresp.ready) begin
                        state  <= dcresp.last ? FETCH : FLUSH;
                        F_offset <= F_offset + 1;
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
