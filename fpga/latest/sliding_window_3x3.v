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


module sliding_window_3x3(
    input              clk,
    input              en,

    input      [7:0]   row0,
    input      [7:0]   row1,
    input      [7:0]   row2,

    output reg [71:0]  win_flat   // 9 × 8 bits
);

    integer i;

    always @(posedge clk) begin
        if (en) begin
            // Shift existing window
            for (i = 0; i < 6; i = i + 1)
                win_flat[i*8 +: 8] <= win_flat[(i+3)*8 +: 8];

            // Insert new column
            win_flat[6*8 +: 8] <= row0;
            win_flat[7*8 +: 8] <= row1;
            win_flat[8*8 +: 8] <= row2;
        end
    end

endmodule
