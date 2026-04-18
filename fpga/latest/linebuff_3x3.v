`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.02.2026 10:02:49
// Design Name: 
// Module Name: linebuff_3x3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module linebuff_3x3 #(
    parameter IMG_W = 28
)(
    input            clk,
    input            en,
    input  [7:0]     pixel_in,

    output reg [7:0] row0,
    output reg [7:0] row1,
    output reg [7:0] row2
);

    reg [7:0] lb1 [0:IMG_W-1];
    reg [7:0] lb2 [0:IMG_W-1];

    integer i;

    always @(posedge clk) begin
        if (en) begin

            // Shift registers
            for (i = IMG_W-1; i > 0; i = i - 1) begin
                lb1[i] <= lb1[i-1];
                lb2[i] <= lb2[i-1];
            end

            // Input stage
            lb1[0] <= pixel_in;
            lb2[0] <= lb1[IMG_W-1];

            // Register outputs (IMPORTANT FIX)
            row0 <= pixel_in;
            row1 <= lb1[IMG_W-1];
            row2 <= lb2[IMG_W-1];
        end
    end

endmodule


