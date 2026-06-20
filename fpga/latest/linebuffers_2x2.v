`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.06.2026 22:41:32
// Design Name: 
// Module Name: linebuffers_2x2
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


module linebuffer_2x2 #(
    parameter IMG_W = 26
)(
    input            clk,
    input            rst,
    input            en,
    input      [20:0] pixel_in,   // ReLU output

    output reg [31:0] row0,       // current row
    output reg [31:0] row1        // previous row
);

    reg [31:0] lb1 [0:IMG_W-1];

    integer i;

    always @(posedge clk) begin

        if(rst) begin

            row0 <= 0;
            row1 <= 0;

            for(i=0;i<IMG_W;i=i+1)
                lb1[i] <= 0;

        end

        else if(en) begin

            // shift buffer
            for(i=IMG_W-1;i>0;i=i-1)
                lb1[i] <= lb1[i-1];

            // insert newest pixel
            lb1[0] <= pixel_in;

            // outputs
            row0 <= pixel_in;
            row1 <= lb1[IMG_W-1];

        end
    end

endmodule