`timescale 1ns / 1ps

module window_gen(
    input  wire              clk,
    input  wire              rst,
    input  wire              valid_in,

    // From line buffer
    input  wire signed [7:0] row0_pix,
    input  wire signed [7:0] row1_pix,
    input  wire signed [7:0] row2_pix,

    // Complete 3x3 window
    output reg signed [7:0] w00,
    output reg signed [7:0] w01,
    output reg signed [7:0] w02,

    output reg signed [7:0] w10,
    output reg signed [7:0] w11,
    output reg signed [7:0] w12,

    output reg signed [7:0] w20,
    output reg signed [7:0] w21,
    output reg signed [7:0] w22,

    output reg valid_out
);

always @(posedge clk)
begin
    if(rst)
    begin
        w00 <= 0; w01 <= 0; w02 <= 0;
        w10 <= 0; w11 <= 0; w12 <= 0;
        w20 <= 0; w21 <= 0; w22 <= 0;
        valid_out <= 0;
    end
    else if(valid_in)
    begin
        // Shift left top row
        w00 <= w01;
        w01 <= w02;
        w02 <= row0_pix;

        // Shift left middle row
        w10 <= w11;
        w11 <= w12;
        w12 <= row1_pix;

        // Shift left bottom row
        w20 <= w21;
        w21 <= w22;
        w22 <= row2_pix;

        valid_out <= 1'b1;
    end
    else
    begin
        valid_out <= 1'b0;
    end
end

endmodule
