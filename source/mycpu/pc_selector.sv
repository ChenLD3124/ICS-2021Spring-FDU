module pc_selector (
    output i32 nxt_pc,
    input i1 exp,eret,ifj,cp0_flush,BEV,
    input i32 EPC,pc_decode,pc_fetch,E_pc,
    input i12 offset
);
    assign nxt_pc = exp?((BEV?32'hbfc00200:32'h80000000)+offset):(cp0_flush?E_pc:(eret?EPC:(ifj?pc_decode:pc_fetch)));
endmodule