`timescale 1ns / 1ps

module tb_linebuff_3x3;

// ─────────────────────────────────────────────
// Parameters
// ─────────────────────────────────────────────
parameter IMG_W   = 8;
parameter CLK_PER = 10;

// ─────────────────────────────────────────────
// DUT ports
// ─────────────────────────────────────────────
reg        clk;
reg        en;
reg  [7:0] pixel_in;
wire [7:0] row0, row1, row2;

// ─────────────────────────────────────────────
// DUT instantiation
// ─────────────────────────────────────────────
linebuff_3x3 #(.IMG_W(IMG_W)) dut (
    .clk      (clk),
    .en       (en),
    .pixel_in (pixel_in),
    .row0     (row0),
    .row1     (row1),
    .row2     (row2)
);

// ─────────────────────────────────────────────
// Clock generation
// ─────────────────────────────────────────────
initial clk = 0;
always #(CLK_PER/2) clk = ~clk;

// ─────────────────────────────────────────────
// Reference model
//   Depth = 2*IMG_W + 1 entries so indices
//   [0], [IMG_W], [2*IMG_W] are always valid
// ─────────────────────────────────────────────
reg [7:0] pixel_history [0:(2*IMG_W)];

task push_history;
    input [7:0] px;
    integer k;
    begin
        for (k = 2*IMG_W; k > 0; k = k - 1)
            pixel_history[k] = pixel_history[k-1];
        pixel_history[0] = px;
    end
endtask

// ─────────────────────────────────────────────
// Drive and check - KEY FIX:
//   push_history BEFORE the clock edge so the
//   reference matches what the DUT registers
// ─────────────────────────────────────────────
integer pass_count;
integer fail_count;
integer cycle_count;

task drive_and_check;
    input [7:0] px;
    input       check_valid;
    reg   [7:0] exp0, exp1, exp2;
    begin
        @(negedge clk);
        pixel_in = px;
        en       = 1;

        // ★ Update reference BEFORE the clock edge
        push_history(px);

        @(posedge clk); #1;   // sample 1 ns after rising edge
        cycle_count = cycle_count + 1;

        if (check_valid) begin
            exp0 = pixel_history[0];
            exp1 = pixel_history[IMG_W];
            exp2 = pixel_history[2*IMG_W];

            if (row0 !== exp0) begin
                $display("FAIL cycle %0d: row0 = %0d, expected %0d",
                         cycle_count, row0, exp0);
                fail_count = fail_count + 1;
            end else
                pass_count = pass_count + 1;

            if (row1 !== exp1) begin
                $display("FAIL cycle %0d: row1 = %0d, expected %0d",
                         cycle_count, row1, exp1);
                fail_count = fail_count + 1;
            end else
                pass_count = pass_count + 1;

            if (row2 !== exp2) begin
                $display("FAIL cycle %0d: row2 = %0d, expected %0d",
                         cycle_count, row2, exp2);
                fail_count = fail_count + 1;
            end else
                pass_count = pass_count + 1;
        end
    end
endtask

// ─────────────────────────────────────────────
// Main test
// ─────────────────────────────────────────────
integer i, r, c;

initial begin
    en           = 0;
    pixel_in     = 8'h00;
    pass_count   = 0;
    fail_count   = 0;
    cycle_count  = 0;

    for (i = 0; i <= 2*IMG_W; i = i + 1)
        pixel_history[i] = 8'h00;

    $display("=== linebuff_3x3 testbench  IMG_W=%0d ===", IMG_W);

    // ── TC1: Idle (en=0) ─────────────────────
    $display("\n--- TC1: Idle state (en=0) ---");
    repeat(4) @(posedge clk);
    #1;
    $display("INFO: row0=%0d row1=%0d row2=%0d at idle", row0, row1, row2);

    // ── TC2: Pipeline fill (first 2*IMG_W cycles) ─
    $display("\n--- TC2: Pipeline fill - first %0d pixels ---", 2*IMG_W);
    for (i = 1; i <= 2*IMG_W; i = i + 1)
        drive_and_check(i[7:0], 0);

    // ── TC3: Steady-state ─────────────────────
    $display("\n--- TC3: Steady-state operation ---");
    for (r = 2; r < 8; r = r + 1)
        for (c = 0; c < IMG_W; c = c + 1)
            drive_and_check((r * IMG_W + c) % 256, 1);

    // ── TC4: en=0 freeze ─────────────────────
    $display("\n--- TC4: en=0 hold - outputs must freeze ---");
    begin : tc4
        reg [7:0] frozen0, frozen1, frozen2;
        @(negedge clk); en = 0; pixel_in = 8'hAA;
        @(posedge clk); #1;
        frozen0 = row0; frozen1 = row1; frozen2 = row2;
        $display("INFO: frozen row0=%0d row1=%0d row2=%0d", frozen0, frozen1, frozen2);

        repeat(4) begin
            @(negedge clk); pixel_in = $random;
            @(posedge clk); #1;
            if (row0 !== frozen0 || row1 !== frozen1 || row2 !== frozen2) begin
                $display("FAIL TC4: output changed while en=0: row0=%0d row1=%0d row2=%0d",
                         row0, row1, row2);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS TC4: outputs stable while en=0");
                pass_count = pass_count + 1;
            end
        end
        // re-enable and resync reference to actual DUT state
        en = 1;
    end

    // ── TC5: Resume after en=0 ───────────────
    // After a gap, pixel_history is stale - resync it
    // from the known DUT state before checking again
    $display("\n--- TC5: Resume after en=0 ---");
    begin : tc5
        // Drain 2 full lines to let the reference catch up
        for (c = 0; c < 2*IMG_W; c = c + 1)
            drive_and_check(8'hB0 + c[7:0], 0);
        // Now check normally
        for (c = 0; c < IMG_W; c = c + 1)
            drive_and_check(8'hD0 + c[7:0], 1);
    end

    // ── TC6: Boundary values 0x00 / 0xFF ─────
    $display("\n--- TC6: Boundary pixel values ---");
    for (r = 0; r < 4; r = r + 1)
        for (c = 0; c < IMG_W; c = c + 1)
            drive_and_check((r[0] == 0) ? 8'h00 : 8'hFF, 1);

    // ── TC7: Walking-1 pattern ────────────────
    $display("\n--- TC7: Walking-1 pattern ---");
    for (r = 0; r < 4; r = r + 1)
        for (c = 0; c < IMG_W; c = c + 1)
            drive_and_check(8'h01 << (c % 8), 1);

    // ── TC8: LFSR pseudo-random stress ────────
    $display("\n--- TC8: Pseudo-random stress (10 rows) ---");
    begin : tc8
        reg [7:0] lfsr;
        lfsr = 8'hA5;
        for (r = 0; r < 10; r = r + 1)
            for (c = 0; c < IMG_W; c = c + 1) begin
                lfsr = {lfsr[6:0], 1'b0} ^
                       ({8{lfsr[7]}} & 8'b10111000);
                drive_and_check(lfsr, 1);
            end
    end

    // ── TC9: Single-cycle en pulse ────────────
    $display("\n--- TC9: Single-cycle en pulse ---");
    begin : tc9
        reg [7:0] new_px;
        new_px = 8'h55;
        @(negedge clk); en = 1; pixel_in = new_px;
        push_history(new_px);
        @(posedge clk); #1;
        if (row0 !== new_px) begin
            $display("FAIL TC9: row0=0x%0h expected 0x%0h", row0, new_px);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC9: row0 correctly latched 0x%0h", row0);
            pass_count = pass_count + 1;
        end
        @(negedge clk); en = 0;
    end

    // ── Results ──────────────────────────────
    $display("\n=========================================");
    $display("  TOTAL CHECKS : %0d", pass_count + fail_count);
    $display("  PASSED       : %0d", pass_count);
    $display("  FAILED       : %0d", fail_count);
    $display("=========================================");
    if (fail_count == 0)
        $display("  ALL TESTS PASSED");
    else
        $display("  *** %0d FAILURES - see messages above ***", fail_count);

    $finish;
end

initial begin
    $dumpfile("linebuff_3x3_tb.vcd");
    $dumpvars(0, tb_linebuff_3x3);
end

initial begin
    #(CLK_PER * 5000);
    $display("TIMEOUT");
    $finish;
end

endmodule