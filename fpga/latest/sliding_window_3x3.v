`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.02.2026 10:04:01
// Design Name: 
// Module Name: sliding_window_3x3
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


module sliding_window_3x3 (
    input clk,
    input rst,
    input valid_in,
    input [7:0] pixel_in,

    output reg valid_out,
    output reg [71:0] win_flat
);

    integer i;

    // line buffers
    reg [7:0] line1 [0:27];
    reg [7:0] line2 [0:27];

    reg [5:0] col;
    reg [5:0] row;

    reg [7:0] p0, p1, p2;

    always @(posedge clk) begin

        if (rst) begin

            col       <= 0;
            row       <= 0;
            valid_out <= 0;
            win_flat  <= 0;

            for(i = 0; i < 28; i = i + 1) begin
                line1[i] <= 0;
                line2[i] <= 0;
            end

        end
        else if(valid_in) begin

            // current column pixels
            p0 = pixel_in;
            p1 = line1[col];
            p2 = line2[col];

            // shift line buffers
            line2[col] <= line1[col];
            line1[col] <= pixel_in;

            // ================= CORRECT WINDOW SHIFT =================
            // row 0
            win_flat[0*8 +: 8]  <= win_flat[1*8 +: 8];
            win_flat[1*8 +: 8]  <= win_flat[2*8 +: 8];
            win_flat[2*8 +: 8]  <= p2;

            // row 1
            win_flat[3*8 +: 8]  <= win_flat[4*8 +: 8];
            win_flat[4*8 +: 8]  <= win_flat[5*8 +: 8];
            win_flat[5*8 +: 8]  <= p1;

            // row 2
            win_flat[6*8 +: 8]  <= win_flat[7*8 +: 8];
            win_flat[7*8 +: 8]  <= win_flat[8*8 +: 8];
            win_flat[8*8 +: 8]  <= p0;

            // =======================================================

            // valid after first 2 rows and 2 cols
            if(row >= 2 && col >= 2)
                valid_out <= 1;
            else
                valid_out <= 0;

            // column counter
            if(col == 27) begin
                col <= 0;
            
                if(row == 27)
                    row <= 0;
                else
                    row <= row + 1;
            end
            else begin
                col <= col + 1;
            end

        end
    end

endmodule