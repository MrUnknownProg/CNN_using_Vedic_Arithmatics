`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2026 14:18:36
// Design Name: 
// Module Name: tb_maxpool
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


module tb_maxpool();
    parameter IMG_W  = 6;     // small size for easy debug
    parameter DATA_W = 20;

    reg clk, rst, en;
    reg signed [DATA_W-1:0] data_in;
    reg valid_in;

    wire signed [DATA_W-1:0] data_out;
    wire valid_out;

    maxpool #(
        .IMG_W(IMG_W),
        .DATA_W(DATA_W)
    ) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .data_in(data_in),
        .valid_in(valid_in),
        .data_out(data_out),
        .valid_out(valid_out)
    );

    // clock
    always #5 clk = ~clk;

    integer i, j;

    // input image (6x6)
    reg signed [DATA_W-1:0] img [0:IMG_W*IMG_W-1];

    // expected pooled output (3x3)
    reg signed [DATA_W-1:0] expected [0:(IMG_W/2)*(IMG_W/2)-1];

    integer out_idx;

    // -----------------------------
    // SEND IMAGE STREAM
    // -----------------------------
    task send_image;
        begin
            for (i = 0; i < IMG_W*IMG_W; i = i + 1) begin
                @(posedge clk);
                data_in  = img[i];
                valid_in = 1;
            end
            @(posedge clk);
            valid_in = 0;
        end
    endtask

    // -----------------------------
    // COMPUTE EXPECTED (GOLDEN)
    // -----------------------------
    task compute_expected;
        integer r, c, idx;
        reg signed [DATA_W-1:0] a,b,c1,d,maxv;
        begin
            idx = 0;
            for (r = 0; r < IMG_W; r = r + 2) begin
                for (c = 0; c < IMG_W; c = c + 2) begin
                    a = img[r*IMG_W + c];
                    b = img[r*IMG_W + c+1];
                    c1 = img[(r+1)*IMG_W + c];
                    d = img[(r+1)*IMG_W + c+1];

                    maxv = a;
                    if (b > maxv) maxv = b;
                    if (c1 > maxv) maxv = c1;
                    if (d > maxv) maxv = d;

                    expected[idx] = maxv;
                    idx = idx + 1;
                end
            end
        end
    endtask

    // -----------------------------
    // MONITOR OUTPUT
    // -----------------------------
    integer pass, fail;

    initial begin
        clk=0; rst=1; en=0;
        data_in=0; valid_in=0;
        pass=0; fail=0;

        #20 rst=0;
        en=1;

        // -----------------------------
        // TC1: Increasing matrix
        // -----------------------------
        $display("\n--- TC1: Increasing values ---");

        for (i=0; i<IMG_W*IMG_W; i=i+1)
            img[i] = i;

        compute_expected();

        out_idx = 0;

        fork
            begin
                send_image();
            end

            begin
                wait(valid_out);
                while (out_idx < (IMG_W/2)*(IMG_W/2)) begin
                    @(posedge clk);
                    if (valid_out) begin
                        if (data_out === expected[out_idx]) begin
                            pass = pass + 1;
                        end else begin
                            $display("FAIL[%0d]: got=%0d exp=%0d",
                                     out_idx, data_out, expected[out_idx]);
                            fail = fail + 1;
                        end
                        out_idx = out_idx + 1;
                    end
                end
            end
        join

        // -----------------------------
        // TC2: All same
        // -----------------------------
        $display("\n--- TC2: All same ---");

        for (i=0; i<IMG_W*IMG_W; i=i+1)
            img[i] = 7;

        compute_expected();
        out_idx = 0;

        fork
            send_image();
            begin
                wait(valid_out);
                while (out_idx < (IMG_W/2)*(IMG_W/2)) begin
                    @(posedge clk);
                    if (valid_out) begin
                        if (data_out !== 7) begin
                            $display("FAIL[%0d]: got=%0d exp=7", out_idx, data_out);
                            fail = fail + 1;
                        end else pass = pass + 1;
                        out_idx = out_idx + 1;
                    end
                end
            end
        join

        // -----------------------------
        // TC3: Random values
        // -----------------------------
        $display("\n--- TC3: Random ---");

        for (i=0; i<IMG_W*IMG_W; i=i+1)
            img[i] = $random % 50;

        compute_expected();
        out_idx = 0;

        fork
            send_image();
            begin
                wait(valid_out);
                while (out_idx < (IMG_W/2)*(IMG_W/2)) begin
                    @(posedge clk);
                    if (valid_out) begin
                        if (data_out !== expected[out_idx]) begin
                            $display("FAIL[%0d]: got=%0d exp=%0d",
                                     out_idx, data_out, expected[out_idx]);
                            fail = fail + 1;
                        end else pass = pass + 1;
                        out_idx = out_idx + 1;
                    end
                end
            end
        join

        // -----------------------------
        // RESULT
        // -----------------------------
        $display("\n=======================");
        $display("PASS=%0d FAIL=%0d", pass, fail);
        $display("=======================");

        if (fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
