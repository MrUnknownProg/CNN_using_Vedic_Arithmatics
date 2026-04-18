//`timescale 1ns/1ps
//module systolic_3x3 (
//    input             clk,
//    input             rst,
//    input             en,
//    input      [7:0]  pixel_in0,
//    input      [7:0]  pixel_in1,
//    input      [7:0]  pixel_in2,
//    // 9 individual kernel weights, one per MAC cell
//    input      [7:0]  weight_in0,  // row0 col0
//    input      [7:0]  weight_in1,  // row0 col1
//    input      [7:0]  weight_in2,  // row0 col2
//    input      [7:0]  weight_in3,  // row1 col0
//    input      [7:0]  weight_in4,  // row1 col1
//    input      [7:0]  weight_in5,  // row1 col2
//    input      [7:0]  weight_in6,  // row2 col0
//    input      [7:0]  weight_in7,  // row2 col1
//    input      [7:0]  weight_in8,  // row2 col2
//    output reg [19:0] out0,out1,out2,
//    output reg [19:0] out3,out4,out5,
//    output reg [19:0] out6,out7,out8
//);
//    wire [19:0] a10,a11,a12;
//    wire [19:0] a20,a21,a22;
//    wire [19:0] mac_out6,mac_out7,mac_out8;

//    // Unused pixel/weight passthroughs
//    wire [7:0] px0,px1,px2,px3,px4,px5,px6,px7,px8;
//    wire [7:0] wx0,wx1,wx2,wx3,wx4,wx5,wx6,wx7,wx8;

//    wire [19:0] a00=20'd0, a01=20'd0, a02=20'd0;

//    // ROW 0 - each MAC gets its own kernel weight
//    mac_vedic m00(clk,en, pixel_in0,px0, weight_in0,wx0, a00,a10);
//    mac_vedic m01(clk,en, pixel_in0,px1, weight_in1,wx1, a01,a11);
//    mac_vedic m02(clk,en, pixel_in0,px2, weight_in2,wx2, a02,a12);
//    // ROW 1
//    mac_vedic m10(clk,en, pixel_in1,px3, weight_in3,wx3, a10,a20);
//    mac_vedic m11(clk,en, pixel_in1,px4, weight_in4,wx4, a11,a21);
//    mac_vedic m12(clk,en, pixel_in1,px5, weight_in5,wx5, a12,a22);
//    // ROW 2
//    mac_vedic m20(clk,en, pixel_in2,px6, weight_in6,wx6, a20,mac_out6);
//    mac_vedic m21(clk,en, pixel_in2,px7, weight_in7,wx7, a21,mac_out7);
//    mac_vedic m22(clk,en, pixel_in2,px8, weight_in8,wx8, a22,mac_out8);

//    always @(posedge clk) begin
//        if (rst) begin
//            out0<=0;out1<=0;out2<=0;
//            out3<=0;out4<=0;out5<=0;
//            out6<=0;out7<=0;out8<=0;
//        end else if (en) begin
//            out0<=a10; out1<=a11; out2<=a12;
//            out3<=a20; out4<=a21; out5<=a22;
//            out6<=mac_out6; out7<=mac_out7; out8<=mac_out8;
//        end
//    end
//endmodule

`timescale 1ns/1ps
module systolic_3x3 (
    input             clk,
    input             rst,
    input             en,

    input      [7:0]  pixel_in0,
    input      [7:0]  pixel_in1,
    input      [7:0]  pixel_in2,

    // 3x3 kernel weights
    input      [7:0]  weight_in0,
    input      [7:0]  weight_in1,
    input      [7:0]  weight_in2,
    input      [7:0]  weight_in3,
    input      [7:0]  weight_in4,
    input      [7:0]  weight_in5,
    input      [7:0]  weight_in6,
    input      [7:0]  weight_in7,
    input      [7:0]  weight_in8,

    output reg [19:0] out0,out1,out2,
    output reg [19:0] out3,out4,out5,
    output reg [19:0] out6,out7,out8
      
);


    // =========================
    // INTERNAL WIRES
    // =========================

    wire [19:0] a10,a11,a12;
    wire [19:0] a20,a21,a22;

    wire [19:0] mac_out6,mac_out7,mac_out8;

    // Pixel propagation
    wire [7:0] px0,px1,px2,px3,px4,px5,px6,px7,px8;

    // Weight propagation
    wire [7:0] wx0,wx1,wx2,wx3,wx4,wx5,wx6,wx7,wx8;

    // Initial accumulators
    wire [19:0] a00 = 20'd0;
    wire [19:0] a01 = 20'd0;
    wire [19:0] a02 = 20'd0;

    // =========================================================
    // SELECT MAC IMPLEMENTATION (ONLY ONE SHOULD BE ACTIVE)
    // =========================================================

    // =========================
    // OPTION 1: VEDIC (DEFAULT - VERIFIED)
    // =========================

    // ROW 0
    mac_vedic m00(clk,en, pixel_in0,px0, weight_in0,wx0, a00,a10);
    mac_vedic m01(clk,en, pixel_in0,px1, weight_in1,wx1, a01,a11);
    mac_vedic m02(clk,en, pixel_in0,px2, weight_in2,wx2, a02,a12);

    // ROW 1
    mac_vedic m10(clk,en, pixel_in1,px3, weight_in3,wx3, a10,a20);
    mac_vedic m11(clk,en, pixel_in1,px4, weight_in4,wx4, a11,a21);
    mac_vedic m12(clk,en, pixel_in1,px5, weight_in5,wx5, a12,a22);

    // ROW 2
    mac_vedic m20(clk,en, pixel_in2,px6, weight_in6,wx6, a20,mac_out6);
    mac_vedic m21(clk,en, pixel_in2,px7, weight_in7,wx7, a21,mac_out7);
    mac_vedic m22(clk,en, pixel_in2,px8, weight_in8,wx8, a22,mac_out8);


    // =========================
    // OPTION 2: BOOTH
    // (Uncomment to use, comment VEDIC above)
    // =========================


//    mac_booth_systolic m00(clk,en, pixel_in0,px0, weight_in0,wx0, a00,a10);
//    mac_booth_systolic m01(clk,en, pixel_in0,px1, weight_in1,wx1, a01,a11);
//    mac_booth_systolic m02(clk,en, pixel_in0,px2, weight_in2,wx2, a02,a12);

//    mac_booth_systolic m10(clk,en, pixel_in1,px3, weight_in3,wx3, a10,a20);
//    mac_booth_systolic m11(clk,en, pixel_in1,px4, weight_in4,wx4, a11,a21);
//    mac_booth_systolic m12(clk,en, pixel_in1,px5, weight_in5,wx5, a12,a22);

//    mac_booth_systolic m20(clk,en, pixel_in2,px6, weight_in6,wx6, a20,mac_out6);
//    mac_booth_systolic m21(clk,en, pixel_in2,px7, weight_in7,wx7, a21,mac_out7);
//    mac_booth_systolic m22(clk,en, pixel_in2,px8, weight_in8,wx8, a22,mac_out8);



    // =========================
    // OPTION 3: DSP
    // (Uncomment to use, comment others)
    // =========================


//    mac_dsp_systolic m00(clk,en, pixel_in0,px0, weight_in0,wx0, a00,a10);
//    mac_dsp_systolic m01(clk,en, pixel_in0,px1, weight_in1,wx1, a01,a11);
//    mac_dsp_systolic m02(clk,en, pixel_in0,px2, weight_in2,wx2, a02,a12);

//    mac_dsp_systolic m10(clk,en, pixel_in1,px3, weight_in3,wx3, a10,a20);
//    mac_dsp_systolic m11(clk,en, pixel_in1,px4, weight_in4,wx4, a11,a21);
//    mac_dsp_systolic m12(clk,en, pixel_in1,px5, weight_in5,wx5, a12,a22);

//    mac_dsp_systolic m20(clk,en, pixel_in2,px6, weight_in6,wx6, a20,mac_out6);
//    mac_dsp_systolic m21(clk,en, pixel_in2,px7, weight_in7,wx7, a21,mac_out7);
//    mac_dsp_systolic m22(clk,en, pixel_in2,px8, weight_in8,wx8, a22,mac_out8);



    // =========================
    // OUTPUT REGISTERING
    // =========================

    always @(posedge clk) begin
        if (rst) begin
            out0<=0; out1<=0; out2<=0;
            out3<=0; out4<=0; out5<=0;
            out6<=0; out7<=0; out8<=0;
        end 
        else if (en) begin
            // Stage outputs
            out0 <= a10; out1 <= a11; out2 <= a12;
            out3 <= a20; out4 <= a21; out5 <= a22;

            // Final outputs
            out6 <= mac_out6;
            out7 <= mac_out7;
            out8 <= mac_out8;
        end
    end

endmodule