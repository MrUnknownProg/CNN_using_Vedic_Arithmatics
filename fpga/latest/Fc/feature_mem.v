module feature_mem(

    input clk,

    // Write Port
    input we,
    input [7:0] wr_addr,
    input signed [19:0] din,

    // Read Port
    input [7:0] rd_addr,
    output reg signed [19:0] dout

);

    // 169 pooled features
    reg signed [19:0] mem [0:168];

    //-----------------------------------------
    // WRITE
    //-----------------------------------------
    always @(posedge clk)
    begin
        if(we)
            mem[wr_addr] <= din;
    end

    //-----------------------------------------
    // READ (Asynchronous)
    //-----------------------------------------
    always @(*)
    begin
        dout = mem[rd_addr];
    end

endmodule
