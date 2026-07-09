module fc_weight_rom(

    input  [10:0] addr,
    output reg signed [7:0] weight

);

    reg signed [7:0] mem [0:1689];

    initial
    begin
        $readmemb("fc_weights.mem", mem);
    end

    always @(*)
    begin
        weight = mem[addr];
    end

endmodule
