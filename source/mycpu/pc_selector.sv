module pc_selector (
    output i32 nxt_pc,
    input i1 exp,eret,ifj,pc_decode,pc_fetch,
    input i32 EPC
);
    assign nxt_pc = exp?0'hbfc00380:(eret?EPC:(ifj?pc_decode:pc_fetch));
endmodule