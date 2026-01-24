`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.01.2026 17:17:51
// Design Name: 
// Module Name: top
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

//(*use_dsp = "yes"*)

module conv3x3_bram_top #(
    parameter IMG_W = 28,
    parameter OUT_W = 26
)(
    input              clk,
    input              en,

    input      [7:0]   pixel_in,

    input      [7:0]   w0,
    input      [7:0]   w1,
    input      [7:0]   w2,

    input      [12:0]  rd_addr,
    input              rd_en,
    output reg [19:0]  rd_data
);

    // Number of sliding windows
    localparam TOTAL_WINDOWS = OUT_W * OUT_W;

    // BRAM: 9 outputs per window
    reg [19:0] fmap_bram [0:TOTAL_WINDOWS*9-1];

    /* ===== Existing pipeline (UNCHANGED) ===== */

    wire [7:0] row0, row1, row2;
    wire [71:0] win_flat;

    line_buffer_3 #(.IMG_W(IMG_W)) lb (
        .clk(clk),
        .en(en),
        .pixel_in(pixel_in),
        .row0(row0),
        .row1(row1),
        .row2(row2)
    );

    sliding_window_3x3 sw (
        .clk(clk),
        .en(en),
        .row0(row0),
        .row1(row1),
        .row2(row2),
        .win_flat(win_flat)
    );

    wire [7:0] p0 = win_flat[6*8 +: 8];
    wire [7:0] p1 = win_flat[7*8 +: 8];
    wire [7:0] p2 = win_flat[8*8 +: 8];

    wire [19:0] o0,o1,o2,o3,o4,o5,o6,o7,o8;

    systolic_3x3 sa (
        .clk(clk),
        .en(en),
        .pixel_in0(p0),
        .pixel_in1(p1),
        .pixel_in2(p2),
        .weight_in0(w0),
        .weight_in1(w1),
        .weight_in2(w2),
        .out0(o0), .out1(o1), .out2(o2),
        .out3(o3), .out4(o4), .out5(o5),
        .out6(o6), .out7(o7), .out8(o8)
    );

    /* ===== BRAM write control ===== */

    integer win_idx = 0;
    reg [3:0] write_sel;
    reg [12:0] wr_addr;
    reg        we;
    
    always @(posedge clk) begin
        if (en) begin
            we <= 1;
    
            case (write_sel)
                0: fmap_bram[wr_addr] <= o0;
                1: fmap_bram[wr_addr] <= o1;
                2: fmap_bram[wr_addr] <= o2;
                3: fmap_bram[wr_addr] <= o3;
                4: fmap_bram[wr_addr] <= o4;
                5: fmap_bram[wr_addr] <= o5;
                6: fmap_bram[wr_addr] <= o6;
                7: fmap_bram[wr_addr] <= o7;
                8: fmap_bram[wr_addr] <= o8;
            endcase
    
            wr_addr   <= win_idx*9 + write_sel;
    
            if (write_sel == 8) begin
                write_sel <= 0;
                win_idx   <= win_idx + 1;
            end else begin
                write_sel <= write_sel + 1;
            end
        end else begin
            we <= 0;
        end
    end


    /* ===== BRAM read port ===== */

    always @(posedge clk) begin
        if (rd_en)
            rd_data <= fmap_bram[rd_addr];
    end

endmodule

