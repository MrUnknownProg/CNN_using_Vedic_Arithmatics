`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.01.2026 09:45:56
// Design Name: 
// Module Name: convo_c1
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

//module convo_c1 (
//    input              clk,
//    input              rst,
//    input              pixel_valid,
//    input      [7:0]   pixel_in,

//    input      [199:0] weight_flat,   // 25 × 8-bit weights

//    output reg [19:0]  conv_out,
//    output reg         out_valid
//);

//    // =========================================================
//    // INTERNAL SIGNALS
//    // =========================================================
//    wire [7:0] row0, row1, row2, row3, row4;
//    wire [199:0] win_flat;

//    wire [7:0] win    [0:24];
//    wire [7:0] weight [0:24];

//    wire  [19:0] acc   [0:25];
    
//    assign acc[0] = 20'd0;

//    // =========================================================
//    // UNPACK FLATTENED BUSES (LEGAL: INTERNAL ONLY)
//    // =========================================================
//    genvar u;
//    generate
//        for (u = 0; u < 25; u = u + 1) begin : UNPACK
//            assign win[u]    = win_flat[u*8 +: 8];
//            assign weight[u] = weight_flat[u*8 +: 8];
//        end
//    endgenerate

//    // =========================================================
//    // LINE BUFFERS (VERTICAL DELAY)
//    // =========================================================
//    line_buffer_5 #(
//        .IMG_W(28)
//    ) LB (
//        .clk      (clk),
//        .en       (pixel_valid),
//        .pixel_in (pixel_in),
//        .row0     (row0),
//        .row1     (row1),
//        .row2     (row2),
//        .row3     (row3),
//        .row4     (row4)
//    );

//    // =========================================================
//    // SLIDING WINDOW (HORIZONTAL SHIFT)
//    // =========================================================
//    sliding_window_5x5 SW (
//        .clk      (clk),
//        .en       (pixel_valid),
//        .row0     (row0),
//        .row1     (row1),
//        .row2     (row2),
//        .row3     (row3),
//        .row4     (row4),
//        .win_flat (win_flat)
//    );

    
//    // =========================================================
//    // 25 PARALLEL MACs (TRUE SYSTOLIC ARRAY)
//    // =========================================================
//    genvar g;
//    generate
//        for (g = 0; g < 25; g = g + 1) begin : SYSTOLIC_MACS
//            (* keep = "true" *)
//            mac_vedic MAC (
//                .clk     (clk),
//                .en      (pixel_valid),
//                .pixel   (win[g]),
//                .weight  (weight[g]),
//                .acc_in  (acc[g]),
//                .acc_out (acc[g+1])
//            );
//        end
//    endgenerate

//    // =========================================================
//    // REGISTERED OUTPUT (ONLY LEGAL WAY)
//    // =========================================================
    
//    always @(posedge clk) begin
//    if (rst) begin
//        conv_out  <= 20'd0;
//        out_valid <= 1'b0;
//    end else begin
//        conv_out  <= acc[25];   // ✅ acc[25] is now a WIRE
//        out_valid <= pixel_valid;
//    end
//end

//endmodule

`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module convo_c1_3x3_systolic (
    input              clk,
    input              rst,
    input              pixel_valid,
    input      [7:0]   pixel_in,

    input      [71:0]  weight_flat,   // 9 × 8-bit weights

    output reg [19:0]  conv_out,
    output reg         out_valid
);

    // =====================================================
    // INTERNAL SIGNALS
    // =====================================================
    wire [7:0] row0, row1, row2;
    wire [71:0] win_flat;

    wire [7:0] win    [0:8];
    wire [7:0] weight [0:8];

    // IMPORTANT: accumulator chain is WIRE (forum fix)
    wire [19:0] acc [0:9];

    // =====================================================
    // UNPACK FLATTENED BUSES
    // =====================================================
    genvar u;
    generate
        for (u = 0; u < 9; u = u + 1) begin : UNPACK
            assign win[u]    = win_flat[u*8 +: 8];
            assign weight[u] = weight_flat[u*8 +: 8];
        end
    endgenerate

    // =====================================================
    // LINE BUFFERS (2 ROW DELAY FOR 3×3)
    // =====================================================
    line_buffer_3 #(
        .IMG_W(28)
    ) LB (
        .clk      (clk),
        .en       (pixel_valid),
        .pixel_in (pixel_in),
        .row0     (row0),
        .row1     (row1),
        .row2     (row2)
    );

    // =====================================================
    // SLIDING WINDOW (3×3)
    // =====================================================
    sliding_window_3x3 SW (
        .clk      (clk),
        .en       (pixel_valid),
        .row0     (row0),
        .row1     (row1),
        .row2     (row2),
        .win_flat (win_flat)
    );

    // =====================================================
    // HEAD OF SYSTOLIC CHAIN (WIRE CONSTANT)
    // =====================================================
    assign acc[0] = 20'd0;

    // =====================================================
    // 9 PARALLEL MACs (TRUE 3×3 SYSTOLIC ARRAY)
    // =====================================================
    genvar g;
    generate
        for (g = 0; g < 9; g = g + 1) begin : SYSTOLIC_MACS
            (* keep = "true" *)
            mac_vedic MAC (
                .clk     (clk),
                .en      (pixel_valid),
                .pixel   (win[g]),
                .weight  (weight[g]),
                .acc_in  (acc[g]),
                .acc_out (acc[g+1])
            );
        end
    endgenerate

    // =====================================================
    // OUTPUT REGISTER (STEP-5 WRITEBACK STAGE)
    // =====================================================
    always @(posedge clk) begin
        if (rst) begin
            conv_out  <= 20'd0;
            out_valid <= 1'b0;
        end else begin
            conv_out  <= acc[9];     // acc[9] is WIRE → LEGAL
            out_valid <= pixel_valid;
        end
    end

endmodule

