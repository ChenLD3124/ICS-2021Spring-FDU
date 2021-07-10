module pc_selector (
    output i32 nxt_pc,
    input i1 exp,eret,ifj,cp0_flush,
    input i32 EPC,pc_decode,pc_fetch,E_pc
);
    assign nxt_pc = exp?0'hbfc00380:(cp0_flush?E_pc:(eret?EPC:(ifj?pc_decode:pc_fetch)));
endmodule