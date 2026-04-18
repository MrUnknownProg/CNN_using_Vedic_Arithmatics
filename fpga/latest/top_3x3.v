//`timescale 1ns/1ps
//module top_3x3 #(
//    parameter IMG_W = 28,
//    parameter OUT_W = 26
//)(
//    input         clk,
//    input         rst,
//    input         en,
//    input  [12:0] rd_addr,
//    input         rd_en,
//    output reg [19:0] rd_data
//);
//    localparam TOTAL_WINDOWS = OUT_W * OUT_W;

//    reg [7:0]  img_bram    [0:IMG_W*IMG_W-1];
//    reg [7:0]  weight_bram [0:8];              // 9 weights for 3x3 kernel
//    reg [19:0] fmap_bram   [0:TOTAL_WINDOWS-1]; // one sum per window

//    reg [12:0] img_addr;
//    wire [7:0] pixel_in = img_bram[img_addr];

//    // All 9 kernel weights
//    wire [7:0] k0=weight_bram[0], k1=weight_bram[1], k2=weight_bram[2];
//    wire [7:0] k3=weight_bram[3], k4=weight_bram[4], k5=weight_bram[5];
//    wire [7:0] k6=weight_bram[6], k7=weight_bram[7], k8=weight_bram[8];

//    always @(posedge clk) begin
//        if (rst) img_addr <= 0;
//        else if (en) img_addr <= img_addr + 1;
//    end

//    wire [7:0] row0, row1, row2;
//    wire [71:0] win_flat;

//    linebuff_3x3 #(.IMG_W(IMG_W)) lb (
//        .clk(clk), .en(en),
//        .pixel_in(pixel_in),
//        .row0(row0), .row1(row1), .row2(row2)
//    );

//    sliding_window_3x3 sw (
//        .clk(clk), .en(en),
//        .row0(row0), .row1(row1), .row2(row2),
//        .win_flat(win_flat)
//    );

//    // Newest column of the sliding window = current 3 pixels
//    wire [7:0] p0 = win_flat[6*8 +: 8];
//    wire [7:0] p1 = win_flat[7*8 +: 8];
//    wire [7:0] p2 = win_flat[8*8 +: 8];

//    wire [19:0] o0,o1,o2,o3,o4,o5,o6,o7,o8;

//    systolic_3x3 sa (
//        .clk(clk), .rst(rst), .en(en),
//        .pixel_in0(p0), .pixel_in1(p1), .pixel_in2(p2),
//        .weight_in0(k0), .weight_in1(k1), .weight_in2(k2),
//        .weight_in3(k3), .weight_in4(k4), .weight_in5(k5),
//        .weight_in6(k6), .weight_in7(k7), .weight_in8(k8),
//        .out0(o0),.out1(o1),.out2(o2),
//        .out3(o3),.out4(o4),.out5(o5),
//        .out6(o6),.out7(o7),.out8(o8)
//    );

//    // Final convolution sum stored per window
//    reg [12:0] win_idx;
//    reg        result_valid;

//    always @(posedge clk) begin
//        if (rst) begin
//            win_idx      <= 0;
//            result_valid <= 0;
//        end else if (en) begin
//            result_valid <= 1;
//            fmap_bram[win_idx] <= o6 + o7 + o8;  // full dot product
//            win_idx <= win_idx + 1;
//        end
//    end

//    always @(posedge clk) begin
//        if (rd_en)
//            rd_data <= fmap_bram[rd_addr];
//    end
//endmodule

//`timescale 1ns/1ps
//module top_3x3 #(
//    parameter IMG_W = 28,
//    parameter OUT_W = 26
//)(
//    input         clk,
//    input         rst,
//    input         en,
//    input  [12:0] rd_addr,
//    input         rd_en,
//    output reg [19:0] rd_data
//);
//    localparam TOTAL_WINDOWS = OUT_W * OUT_W;

//    reg [7:0]  img_bram    [0:IMG_W*IMG_W-1];
//    reg [7:0]  weight_bram [0:8];
//    reg [19:0] fmap_bram   [0:TOTAL_WINDOWS-1];

//    reg [12:0] img_addr;
//    wire [7:0] pixel_in = img_bram[img_addr];

//    wire [7:0] k0=weight_bram[0], k1=weight_bram[1], k2=weight_bram[2];
//    wire [7:0] k3=weight_bram[3], k4=weight_bram[4], k5=weight_bram[5];
//    wire [7:0] k6=weight_bram[6], k7=weight_bram[7], k8=weight_bram[8];

//    always @(posedge clk) begin
//        if (rst) img_addr <= 0;
//        else if (en) img_addr <= img_addr + 1;
//    end

//    wire [7:0] row0, row1, row2;
//    wire [71:0] win_flat;

//    linebuff_3x3 #(.IMG_W(IMG_W)) lb (
//        .clk(clk), .en(en),
//        .pixel_in(pixel_in),
//        .row0(row0), .row1(row1), .row2(row2)
//    );

//    sliding_window_3x3 sw (
//        .clk(clk), .en(en),
//        .row0(row0), .row1(row1), .row2(row2),
//        .win_flat(win_flat)
//    );

//    wire [7:0] p0 = win_flat[6*8 +: 8];
//    wire [7:0] p1 = win_flat[7*8 +: 8];
//    wire [7:0] p2 = win_flat[8*8 +: 8];

//    wire [19:0] o0,o1,o2,o3,o4,o5,o6,o7,o8;

//    systolic_3x3 sa (
//        .clk(clk), .rst(rst), .en(en),
//        .pixel_in0(p0), .pixel_in1(p1), .pixel_in2(p2),
//        .weight_in0(k0), .weight_in1(k1), .weight_in2(k2),
//        .weight_in3(k3), .weight_in4(k4), .weight_in5(k5),
//        .weight_in6(k6), .weight_in7(k7), .weight_in8(k8),
//        .out0(o0),.out1(o1),.out2(o2),
//        .out3(o3),.out4(o4),.out5(o5),
//        .out6(o6),.out7(o7),.out8(o8)
//    );

//    // 🔽 NEW: convolution sum + ReLU
//    wire signed [19:0] conv_sum;
//    wire signed [19:0] relu_out;

//    assign conv_sum = o6 + o7 + o8;

//    ReLU relu_inst (
//        .in(conv_sum),
//        .out(relu_out)
//    );

//    reg [12:0] win_idx;
//    reg        result_valid;

//    always @(posedge clk) begin
//        if (rst) begin
//            win_idx      <= 0;
//            result_valid <= 0;
//        end else if (en) begin
//            result_valid <= 1;
//            fmap_bram[win_idx] <= relu_out;   // ✅ ReLU applied
//            win_idx <= win_idx + 1;
//        end
//    end

//    always @(posedge clk) begin
//        if (rd_en)
//            rd_data <= fmap_bram[rd_addr];
//    end
//endmodule

`timescale 1ns/1ps
module top_3x3 #(
    parameter IMG_W = 28,
    parameter OUT_W = 26
)(
    input         clk,
    input         rst,
    input         en,
    input  [12:0] rd_addr,
    input         rd_en,
    output reg signed [19:0] rd_data
);

    localparam TOTAL_WINDOWS = OUT_W * OUT_W;

    // ✅ NEW: pooling params
    localparam POOL_W = OUT_W / 2;             // 13
    localparam TOTAL_POOL = POOL_W * POOL_W;   // 169

    // ✅ SIGNED memories
    reg signed [7:0]  img_bram    [0:IMG_W*IMG_W-1];
    reg signed [7:0]  weight_bram [0:8];
    reg signed [19:0] fmap_bram   [0:TOTAL_WINDOWS-1];

    // ✅ NEW: pooled output memory
    reg signed [19:0] pool_bram   [0:TOTAL_POOL-1];

    reg [12:0] img_addr;
    wire signed [7:0] pixel_in = img_bram[img_addr];

    // weights
    wire signed [7:0] k0=weight_bram[0], k1=weight_bram[1], k2=weight_bram[2];
    wire signed [7:0] k3=weight_bram[3], k4=weight_bram[4], k5=weight_bram[5];
    wire signed [7:0] k6=weight_bram[6], k7=weight_bram[7], k8=weight_bram[8];

    always @(posedge clk) begin
        if (rst) img_addr <= 0;
        else if (en) img_addr <= img_addr + 1;
    end

    wire signed [7:0] row0, row1, row2;
    wire [71:0] win_flat;

    linebuff_3x3 #(.IMG_W(IMG_W)) lb (
        .clk(clk), .en(en),
        .pixel_in(pixel_in),
        .row0(row0), .row1(row1), .row2(row2)
    );

    sliding_window_3x3 sw (
        .clk(clk), .en(en),
        .row0(row0), .row1(row1), .row2(row2),
        .win_flat(win_flat)
    );

    // Extract pixels
    wire signed [7:0] p0 = win_flat[6*8 +: 8];
    wire signed [7:0] p1 = win_flat[7*8 +: 8];
    wire signed [7:0] p2 = win_flat[8*8 +: 8];

    wire signed [19:0] o0,o1,o2,o3,o4,o5,o6,o7,o8;

    systolic_3x3 sa (
        .clk(clk), .rst(rst), .en(en),
        .pixel_in0(p0), .pixel_in1(p1), .pixel_in2(p2),
        .weight_in0(k0), .weight_in1(k1), .weight_in2(k2),
        .weight_in3(k3), .weight_in4(k4), .weight_in5(k5),
        .weight_in6(k6), .weight_in7(k7), .weight_in8(k8),
        .out0(o0),.out1(o1),.out2(o2),
        .out3(o3),.out4(o4),.out5(o5),
        .out6(o6),.out7(o7),.out8(o8)
    );

    // Convolution sum
    wire signed [19:0] conv_sum;
    assign conv_sum = o6 + o7 + o8;

    // ReLU
    wire signed [19:0] relu_out;

    ReLU relu_inst (
        .in(conv_sum),
        .out(relu_out)
    );

    reg [12:0] win_idx;
    reg        result_valid;

    always @(posedge clk) begin
        if (rst) begin
            win_idx      <= 0;
            result_valid <= 0;
        end else if (en) begin
            result_valid <= 1;
            fmap_bram[win_idx] <= relu_out;   // kept (optional debug)
            win_idx <= win_idx + 1;
        end
    end

    // =========================================================
    // ✅ MAXPOOL (2x2, STRIDE=2, SLIDING)
    // =========================================================

    wire signed [19:0] pool_out;
    wire pool_valid;

    maxpool #(
        .IMG_W(OUT_W),
        .DATA_W(20)
    ) pool_inst (
        .clk(clk),
        .rst(rst),
        .en(en),
        .data_in(relu_out),
        .valid_in(result_valid),
        .data_out(pool_out),
        .valid_out(pool_valid)
    );

    // store pooled output
    reg [12:0] pool_idx;

    always @(posedge clk) begin
        if (rst) begin
            pool_idx <= 0;
        end else if (pool_valid) begin
            pool_bram[pool_idx] <= pool_out;
            pool_idx <= pool_idx + 1;
        end
    end

    // =========================================================
    // READ OUTPUT (NOW FROM POOL)
    // =========================================================
    always @(posedge clk) begin
        if (rd_en)
            rd_data <= pool_bram[rd_addr];
    end

endmodule