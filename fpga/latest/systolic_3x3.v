`timescale 1ns/1ps
module systolic_3x3 (
    input             clk,
    input             rst,
    input             en,

    input      signed [7:0]  pixel_in0,
    input      signed [7:0]  pixel_in1,
    input      signed [7:0]  pixel_in2,

    // 3x3 kernel weights
    input      signed [7:0]  weight_in0,
    input      signed [7:0]  weight_in1,
    input      signed [7:0]  weight_in2,
    input      signed [7:0]  weight_in3,
    input      signed [7:0]  weight_in4,
    input      signed [7:0]  weight_in5,
    input      signed [7:0]  weight_in6,
    input      signed [7:0]  weight_in7,
    input      signed [7:0]  weight_in8,

    output reg signed [19:0] out0,out1,out2,
    output reg signed [19:0] out3,out4,out5,
    output reg signed [19:0] out6,out7,out8
);

    // =========================
    // INTERNAL WIRES
    // =========================

    wire signed [19:0] a10,a11,a12;
    wire signed [19:0] a20,a21,a22;

    wire signed [19:0] mac_out6,mac_out7,mac_out8;

    // Pixel propagation
    wire signed [7:0] px0,px1,px2,px3,px4,px5,px6,px7,px8;

    // Weight propagation
    wire signed [7:0] wx0,wx1,wx2,wx3,wx4,wx5,wx6,wx7,wx8;

    // Initial accumulators
    wire signed [19:0] a00 = 20'sd0;
    wire signed [19:0] a01 = 20'sd0;
    wire signed [19:0] a02 = 20'sd0;

    // =========================================================
    // SELECT MAC IMPLEMENTATION (ONLY ONE SHOULD BE ACTIVE)
    // =========================================================

    // =========================
    // OPTION 1: VEDIC (DEFAULT - VERIFIED)
    // =========================

    // ================= SYSTOLIC =================

    wire signed [19:0] o0,o1,o2,o3,o4,o5,o6,o7,o8;

    // ================= DELAYS =================

//    reg signed [19:0] d0,d1,d2,d3,d4,d5;

//   always @(posedge clk) begin
//    if(rst) begin
//        d0<=0; d1<=0; d2<=0;
//        d3<=0; d4<=0; d5<=0;
//    end
//    else if(en) begin
//        d0 <= o0;
//        d1 <= o1;
//        d2 <= o2;

//        d3 <= o3;
//        d4 <= o4;
//        d5 <= o5;
//    end
//end

    // ================= ROW 1 =================
    
    mac_vedic m00(clk,en,rst,pixel_in0,px0,weight_in0,wx0,20'sd0,o0);
    mac_vedic m01(clk,en,rst,px0,px1,weight_in1,wx1,20'sd0,o1);
    mac_vedic m02(clk,en,rst,px1,px2,weight_in2,wx2,20'sd0,o2);
    
    // ================= ROW 2 =================
    
    mac_vedic m10(clk,en,rst,pixel_in1,px3,weight_in3,wx3,o0,o3);
    mac_vedic m11(clk,en,rst,px3,px4,weight_in4,wx4,o1,o4);
    mac_vedic m12(clk,en,rst,px4,px5,weight_in5,wx5,o2,o5);
    
    // ================= ROW 3 =================
    
    mac_vedic m20(clk,en,rst,pixel_in2,px6,weight_in6,wx6,o3,o6);
    mac_vedic m21(clk,en,rst,px6,px7,weight_in7,wx7,o4,o7);
    mac_vedic m22(clk,en,rst,px7,px8,weight_in8,wx8,o5,o8);

    assign a10 = o0;
    assign a11 = o1;
    assign a12 = o2;

    assign a20 = o3;
    assign a21 = o4;
    assign a22 = o5;

    assign mac_out6 = o6;
    assign mac_out7 = o7;
    assign mac_out8 = o8;

    // =========================
    // OPTION 2: BOOTH
    // (Uncomment to use, comment VEDIC above)
    // =========================

//   mac_unit_8bit m00(clk,en, pixel_in0,px0, weight_in0,wx0, a00,a10);
//   mac_unit_8bit m01(clk,en, pixel_in0,px1, weight_in1,wx1, a01,a11);
//   mac_unit_8bit m02(clk,en, pixel_in0,px2, weight_in2,wx2, a02,a12);

//   mac_unit_8bit m10(clk,en, pixel_in1,px3, weight_in3,wx3, a10,a20);
//   mac_unit_8bit m11(clk,en, pixel_in1,px4, weight_in4,wx4, a11,a21);
//   mac_unit_8bit m12(clk,en, pixel_in1,px5, weight_in5,wx5, a12,a22);

//   mac_unit_8bit m20(clk,en, pixel_in2,px6, weight_in6,wx6, a20,mac_out6);
//   mac_unit_8bit m21(clk,en, pixel_in2,px7, weight_in7,wx7, a21,mac_out7);
//   mac_unit_8bit m22(clk,en, pixel_in2,px8, weight_in8,wx8, a22,mac_out8);

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
reg dbg_done;

always @(posedge clk)
begin
    if(rst)
        dbg_done <= 0;

    else if(!dbg_done && out8 != 0)
    begin
        dbg_done <= 1;

        $display("================================");
        $display("PIXELS");

        $display("IN0=%0d PX0=%0d PX1=%0d",
                 pixel_in0, px0, px1);

        $display("IN1=%0d PX3=%0d PX4=%0d",
                 pixel_in1, px3, px4);

        $display("IN2=%0d PX6=%0d PX7=%0d",
                 pixel_in2, px6, px7);

        $display("================================");
    end
end
endmodule
