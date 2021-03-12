`include "pipeline.svh"
module write_back(
    input W_type W,
    output word_t wd3,
    output creg_addr_t wa3,
    output logic write_enable
);
    assign wa3=W.regw;
    assign wd3 = W.m?dresp.data:W.valA;
    assign write_enable=W.wen;
endmodule