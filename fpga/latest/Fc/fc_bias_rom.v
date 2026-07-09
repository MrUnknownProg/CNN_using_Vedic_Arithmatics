module fc_bias_rom(

    input [3:0] addr,
    output reg signed [15:0] bias

);

    reg signed [15:0] mem [0:9];

    initial
    begin
        $readmemb("fc_bias.mem", mem);
    end

    always @(*)
    begin
        bias = mem[addr];
    end

endmodule
