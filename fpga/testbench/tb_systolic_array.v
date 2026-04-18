`timescale 1ns/1ps
module tb_systolic_3x3;

    reg        clk, rst, en;
    reg  [7:0] pixel_in0, pixel_in1, pixel_in2;
    reg  [7:0] weight_in0, weight_in1, weight_in2;
    wire[19:0] out0,out1,out2,out3,out4,out5,out6,out7,out8;

    systolic_3x3 dut (
        .clk(clk), .rst(rst), .en(en),
        .pixel_in0(pixel_in0), .pixel_in1(pixel_in1), .pixel_in2(pixel_in2),
        .weight_in0(weight_in0), .weight_in1(weight_in1), .weight_in2(weight_in2),
        .out0(out0),.out1(out1),.out2(out2),
        .out3(out3),.out4(out4),.out5(out5),
        .out6(out6),.out7(out7),.out8(out8)
    );

    always #5 clk = ~clk;

    integer cyc;
    integer pass_count, fail_count;

    task apply_and_print;
        input [7:0] p0,p1,p2,w0,w1,w2;
        input integer c;
        begin
            @(negedge clk);
            pixel_in0=p0; pixel_in1=p1; pixel_in2=p2;
            weight_in0=w0; weight_in1=w1; weight_in2=w2;
            @(posedge clk); #1;
            $display("%3d | p=[%2d %2d %2d] w=[%2d %2d %2d] | out0-2=[%5d %5d %5d] | out3-5=[%5d %5d %5d] | out6-8=[%5d %5d %5d] | sum=%0d",
                c, p0,p1,p2, w0,w1,w2,
                out0,out1,out2,
                out3,out4,out5,
                out6,out7,out8,
                out6+out7+out8);
        end
    endtask

    task check;
        input [19:0] got, exp;
        input [63:0] idx;
        begin
            if (got===exp) begin
                $display("  PASS out%0d = %0d", idx, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL out%0d got=%0d expected=%0d", idx, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clk=0; rst=1; en=0;
        pixel_in0=0; pixel_in1=0; pixel_in2=0;
        weight_in0=0; weight_in1=0; weight_in2=0;
        pass_count=0; fail_count=0;

        #20; rst=0; en=1;

        $display("=== 3x3 Convolution Test ===");
        $display("Image : [1 2 3 / 4 5 6 / 7 8 9]");
        $display("Kernel: all 1s  Expected sum = 45");
        $display("");
        $display("Input fed column by column:");
        $display("  Col0: row0=1 row1=4 row2=7");
        $display("  Col1: row0=2 row1=5 row2=8");
        $display("  Col2: row0=3 row1=6 row2=9");
        $display("");

        // Feed one column per cycle
        apply_and_print(1,4,7, 1,1,1, 1);   // col0
        apply_and_print(2,5,8, 1,1,1, 2);   // col1
        apply_and_print(3,6,9, 1,1,1, 3);   // col2

        // Drain pipeline (1 cycle for single-stage MAC)
        apply_and_print(0,0,0, 0,0,0, 4);

        $display("");
        $display("=== TC1: Reset check ===");
        @(negedge clk); rst=1; en=0;
        @(posedge clk); #1;
        if (|{out0,out1,out2,out3,out4,out5,out6,out7,out8}) begin
            $display("  FAIL: outputs not zero after rst");
            fail_count = fail_count + 1;
        end else begin
            $display("  PASS: all outputs zero after rst");
            pass_count = pass_count + 1;
        end
        @(negedge clk); rst=0; en=1;

        $display("");
        $display("=== TC2: Convolution result at cycle 4 ===");
        // Replay and sample at cycle 4
        apply_and_print(1,4,7, 1,1,1, 1);
        apply_and_print(2,5,8, 1,1,1, 2);
        apply_and_print(3,6,9, 1,1,1, 3);
        apply_and_print(0,0,0, 0,0,0, 4);
        check(out6+out7+out8, 20'd45, 6);

        $display("");
        $display("=== TC3: Zero image ===");
        @(negedge clk); rst=1;
        @(posedge clk); #1;
        @(negedge clk); rst=0; en=1;
        repeat(4) apply_and_print(0,0,0, 1,1,1, 0);
        if (|{out6,out7,out8}) begin
            $display("  FAIL: non-zero output for zero image");
            fail_count = fail_count + 1;
        end else begin
            $display("  PASS: zero output for zero image");
            pass_count = pass_count + 1;
        end

        $display("");
        $display("=== TC4: Zero kernel ===");
        @(negedge clk); rst=1;
        @(posedge clk); #1;
        @(negedge clk); rst=0; en=1;
        apply_and_print(1,4,7, 0,0,0, 1);
        apply_and_print(2,5,8, 0,0,0, 2);
        apply_and_print(3,6,9, 0,0,0, 3);
        apply_and_print(0,0,0, 0,0,0, 4);
        if (|{out6,out7,out8}) begin
            $display("  FAIL: non-zero output for zero kernel");
            fail_count = fail_count + 1;
        end else begin
            $display("  PASS: zero output for zero kernel");
            pass_count = pass_count + 1;
        end

        $display("");
        $display("=== TC5: en=0 freeze ===");
        @(negedge clk); rst=1;
        @(posedge clk); #1;
        @(negedge clk); rst=0; en=1;
        apply_and_print(1,4,7, 1,1,1, 1);
        apply_and_print(2,5,8, 1,1,1, 2);
        apply_and_print(3,6,9, 1,1,1, 3);
        apply_and_print(0,0,0, 0,0,0, 4);
        begin : tc5
            reg [19:0] snap6, snap7, snap8;
            snap6=out6; snap7=out7; snap8=out8;
            @(negedge clk); en=0;
            repeat(3) begin
                @(negedge clk); pixel_in0=$random; pixel_in1=$random; pixel_in2=$random;
                @(posedge clk); #1;
                if (out6!==snap6 || out7!==snap7 || out8!==snap8) begin
                    $display("  FAIL: outputs changed with en=0");
                    fail_count = fail_count + 1;
                end else begin
                    $display("  PASS: outputs frozen with en=0");
                    pass_count = pass_count + 1;
                end
            end
            en=1;
        end

        $display("");
        $display("=========================================");
        $display("  PASSED: %0d   FAILED: %0d", pass_count, fail_count);
        $display("=========================================");

        $finish;
    end

    initial begin
        $dumpfile("systolic_conv_tb.vcd");
        $dumpvars(0, tb_systolic_3x3);
    end
endmodule