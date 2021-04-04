`include "pipeline.svh"
module write_back(
    input W_type W,
    // input i32 dresp_data,
    output word_t wd3,
    output creg_addr_t wa3,
    output logic write_enable,
    // input i32 hi,lo,
    output i1 hi_write, lo_write,
    output i32 hi_data, lo_data
);
    assign wa3=W.regw;
    // assign wd3 = W.rm?dresp_data:W.valA;
    assign wd3 = W.valA;
    assign write_enable=W.wen;
    assign hi_write = W.hi_w;
    assign lo_write = W.lo_w;
    assign hi_data = W.valA;
    assign lo_data = W.valB;
endmodule