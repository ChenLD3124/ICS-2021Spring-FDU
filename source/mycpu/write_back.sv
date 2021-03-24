`include "pipeline.svh"
module write_back(
    input W_type W,
    // input i32 dresp_data,
    output word_t wd3,
    output creg_addr_t wa3,
    output logic write_enable
);
    assign wa3=W.regw;
    // assign wd3 = W.rm?dresp_data:W.valA;
    assign wd3 = W.valA;
    assign write_enable=W.wen;
endmodule