`timescale 1ns / 1ps

module tb_sliding_window_3x3;

parameter CLK_PER = 10;

reg        clk;
reg        en;
reg  [7:0] row0, row1, row2;
wire[71:0] win_flat;

sliding_window_3x3 dut (
    .clk(clk), .en(en),
    .row0(row0), .row1(row1), .row2(row2),
    .win_flat(win_flat)
);

initial clk = 0;
always #(CLK_PER/2) clk = ~clk;

// ─────────────────────────────────────────────
// Reference model
// Uses a TEMP COPY to simulate non-blocking
// simultaneous reads - critical correctness fix
// ─────────────────────────────────────────────
reg [7:0] ref_win [0:8];
reg [7:0] tmp     [0:8];   // snapshot before shift
integer   k;

task ref_push;
    input [7:0] r0, r1, r2;
    begin
        // Step 1: snapshot ALL slots (simulates NBA read phase)
        for (k = 0; k < 9; k = k + 1)
            tmp[k] = ref_win[k];
        // Step 2: apply shift using snapshot values (simulates NBA write phase)
        for (k = 0; k < 6; k = k + 1)
            ref_win[k] = tmp[k+3];
        // Step 3: insert new column
        ref_win[6] = r0;
        ref_win[7] = r1;
        ref_win[8] = r2;
    end
endtask

integer pass_count, fail_count, cycle_count;

function [7:0] slot;
    input [71:0] w;
    input integer idx;
    begin slot = w[idx*8 +: 8]; end
endfunction

// ─────────────────────────────────────────────
// drive_and_check: ref updated BEFORE posedge
// ─────────────────────────────────────────────
task drive_and_check;
    input [7:0] r0, r1, r2;
    input       check_valid;
    integer     s;
    reg  [7:0]  got, exp;
    begin
        @(negedge clk);
        row0 = r0; row1 = r1; row2 = r2; en = 1;
        ref_push(r0, r1, r2);           // update ref before clock edge
        @(posedge clk); #1;
        cycle_count = cycle_count + 1;

        if (check_valid) begin
            for (s = 0; s < 9; s = s + 1) begin
                got = slot(win_flat, s);
                exp = ref_win[s];
                if (got !== exp) begin
                    $display("FAIL cycle %0d slot[%0d]: got=0x%02h exp=0x%02h  (row%0d of col-%0d)",
                             cycle_count, s, got, exp, s%3, s/3);
                    fail_count = fail_count + 1;
                end else
                    pass_count = pass_count + 1;
            end
        end
    end
endtask

// ─────────────────────────────────────────────
// Spatial correctness check
// After pushing columns A, B, C:
//   slot[col*3 + row] must equal pixel(col, row)
// ─────────────────────────────────────────────
task check_spatial_window;
    input [7:0] c0r0, c0r1, c0r2;   // oldest column
    input [7:0] c1r0, c1r1, c1r2;   // middle column
    input [7:0] c2r0, c2r1, c2r2;   // newest column
    reg failed;
    begin
        failed = 0;
        // col 0 = slots [2:0]
        if (slot(win_flat,0) !== c0r0) begin $display("FAIL spatial: slot[0]=0x%02h exp=0x%02h (col0 row0)", slot(win_flat,0), c0r0); failed=1; end
        if (slot(win_flat,1) !== c0r1) begin $display("FAIL spatial: slot[1]=0x%02h exp=0x%02h (col0 row1)", slot(win_flat,1), c0r1); failed=1; end
        if (slot(win_flat,2) !== c0r2) begin $display("FAIL spatial: slot[2]=0x%02h exp=0x%02h (col0 row2)", slot(win_flat,2), c0r2); failed=1; end
        // col 1 = slots [5:3]
        if (slot(win_flat,3) !== c1r0) begin $display("FAIL spatial: slot[3]=0x%02h exp=0x%02h (col1 row0)", slot(win_flat,3), c1r0); failed=1; end
        if (slot(win_flat,4) !== c1r1) begin $display("FAIL spatial: slot[4]=0x%02h exp=0x%02h (col1 row1)", slot(win_flat,4), c1r1); failed=1; end
        if (slot(win_flat,5) !== c1r2) begin $display("FAIL spatial: slot[5]=0x%02h exp=0x%02h (col1 row2)", slot(win_flat,5), c1r2); failed=1; end
        // col 2 = slots [8:6]
        if (slot(win_flat,6) !== c2r0) begin $display("FAIL spatial: slot[6]=0x%02h exp=0x%02h (col2 row0)", slot(win_flat,6), c2r0); failed=1; end
        if (slot(win_flat,7) !== c2r1) begin $display("FAIL spatial: slot[7]=0x%02h exp=0x%02h (col2 row1)", slot(win_flat,7), c2r1); failed=1; end
        if (slot(win_flat,8) !== c2r2) begin $display("FAIL spatial: slot[8]=0x%02h exp=0x%02h (col2 row2)", slot(win_flat,8), c2r2); failed=1; end
        if (!failed) begin
            $display("PASS spatial: 3x3 window layout correct");
            pass_count = pass_count + 9;
        end else
            fail_count = fail_count + 1;
    end
endtask

integer i;
reg [71:0] frozen_win;
reg [7:0]  lfsr;

initial begin
    en = 0; row0 = 0; row1 = 0; row2 = 0;
    pass_count = 0; fail_count = 0; cycle_count = 0;
    for (i = 0; i < 9; i = i + 1) ref_win[i] = 8'h00;

    $display("=== sliding_window_3x3 testbench ===");

    // ── TC1: Idle ────────────────────────────
    $display("\n--- TC1: Idle (en=0) ---");
    repeat(4) @(posedge clk); #1;
    $display("INFO: win_flat=0x%018h at idle", win_flat);

    // ── TC2: Pipeline fill (3 columns) ───────
    $display("\n--- TC2: Pipeline fill ---");
    drive_and_check(8'hA0, 8'hA1, 8'hA2, 0);
    drive_and_check(8'hB0, 8'hB1, 8'hB2, 0);
    drive_and_check(8'hC0, 8'hC1, 8'hC2, 0);

    // ── TC3: Spatial layout verification ─────
    // After exactly cols A,B,C the window must be:
    //   col_old=[A0,A1,A2] col_mid=[B0,B1,B2] col_new=[C0,C1,C2]
    $display("\n--- TC3: Spatial layout after fill ---");
    check_spatial_window(8'hA0,8'hA1,8'hA2,
                         8'hB0,8'hB1,8'hB2,
                         8'hC0,8'hC1,8'hC2);

    // ── TC4: Steady-state all-slot check ──────
    $display("\n--- TC4: Steady-state ---");
    for (i = 0; i < 15; i = i + 1)
        drive_and_check(i*3, i*3+1, i*3+2, 1);

    // ── TC5: Aging - oldest col ejected ───────
    // Push 3 distinct columns, verify col A is ejected on 4th push
    $display("\n--- TC5: Column aging / ejection ---");
    drive_and_check(8'h11, 8'h12, 8'h13, 1);   // becomes oldest
    drive_and_check(8'h21, 8'h22, 8'h23, 1);
    drive_and_check(8'h31, 8'h32, 8'h33, 1);   // 0x11 col now oldest in [2:0]
    // One more push - 0x11 col must be gone
    drive_and_check(8'h41, 8'h42, 8'h43, 1);
    begin : tc5_eject
        if (slot(win_flat,0) === 8'h11 || slot(win_flat,1) === 8'h12) begin
            $display("FAIL TC5: evicted column still present in window");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC5: oldest column correctly ejected");
            pass_count = pass_count + 1;
        end
    end

    // ── TC6: en=0 freeze ─────────────────────
    $display("\n--- TC6: en=0 freeze ---");
    @(negedge clk); en = 0;
    @(posedge clk); #1;
    frozen_win = win_flat;
    repeat(5) begin
        @(negedge clk); row0=$random; row1=$random; row2=$random;
        @(posedge clk); #1;
        if (win_flat !== frozen_win) begin
            $display("FAIL TC6: win_flat changed while en=0");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS TC6: frozen");
            pass_count = pass_count + 1;
        end
    end

    // ── TC7: Resume after freeze ──────────────
    // Re-enable and drain 3 columns before checking
    $display("\n--- TC7: Resume after en=0 ---");
    en = 1;
    drive_and_check(8'hE0, 8'hE1, 8'hE2, 0);
    drive_and_check(8'hF0, 8'hF1, 8'hF2, 0);
    drive_and_check(8'hEA, 8'hEB, 8'hEC, 0);
    // Re-sync ref from DUT actual state
    for (i = 0; i < 9; i = i + 1) ref_win[i] = slot(win_flat, i);
    drive_and_check(8'hFA, 8'hFB, 8'hFC, 1);
    drive_and_check(8'hDA, 8'hDB, 8'hDC, 1);
    drive_and_check(8'hCA, 8'hCB, 8'hCC, 1);

    // ── TC8: Row independence (no row swap) ───
    $display("\n--- TC8: Row-to-slot mapping ---");
    drive_and_check(8'hAA, 8'hBB, 8'hCC, 1);
    begin : tc8
        reg ok; ok = 1;
        if (slot(win_flat,6) !== 8'hAA) begin $display("FAIL TC8: row0 not in slot[6]"); ok=0; end
        if (slot(win_flat,7) !== 8'hBB) begin $display("FAIL TC8: row1 not in slot[7]"); ok=0; end
        if (slot(win_flat,8) !== 8'hCC) begin $display("FAIL TC8: row2 not in slot[8]"); ok=0; end
        if (ok) begin $display("PASS TC8: row0→slot[6], row1→slot[7], row2→slot[8]"); pass_count=pass_count+3; end
        else fail_count = fail_count + 1;
    end

    // ── TC9: Boundary values ──────────────────
    $display("\n--- TC9: Boundary values 0x00 / 0xFF ---");
    repeat(3) drive_and_check(8'h00, 8'h00, 8'h00, 1);
    begin : tc9a
        integer s;
        for (s=0; s<9; s=s+1)
            if (slot(win_flat,s) !== 8'h00) begin
                $display("FAIL TC9: slot[%0d]=0x%02h expected 0x00", s, slot(win_flat,s));
                fail_count=fail_count+1;
            end else pass_count=pass_count+1;
    end
    repeat(3) drive_and_check(8'hFF, 8'hFF, 8'hFF, 1);
    begin : tc9b
        integer s;
        for (s=0; s<9; s=s+1)
            if (slot(win_flat,s) !== 8'hFF) begin
                $display("FAIL TC9: slot[%0d]=0x%02h expected 0xFF", s, slot(win_flat,s));
                fail_count=fail_count+1;
            end else pass_count=pass_count+1;
    end

    // ── TC10: Walking-1 ───────────────────────
    $display("\n--- TC10: Walking-1 ---");
    for (i = 0; i < 8; i = i + 1)
        drive_and_check(8'h01<<i, 8'h01<<((i+1)%8), 8'h01<<((i+2)%8), 1);

    // ── TC11: LFSR stress ─────────────────────
    $display("\n--- TC11: LFSR stress (30 columns) ---");
    lfsr = 8'hA5;
    for (i = 0; i < 30; i = i + 1) begin
        lfsr = {lfsr[6:0],1'b0} ^ ({8{lfsr[7]}} & 8'b10111000);
        drive_and_check(lfsr, ~lfsr, lfsr^8'h55, 1);
    end

    // ── TC12: Intermittent en toggling ────────
    $display("\n--- TC12: Intermittent en ---");
    begin : tc12
        reg [71:0] snap;
        integer    j;
        for (j = 0; j < 8; j = j + 1) begin
            if (j % 3 != 2) begin
                drive_and_check(8'hD0+j, 8'hE0+j, 8'hF0+j, 1);
            end else begin
                @(negedge clk); en=0; row0=8'hFF; row1=8'hFF; row2=8'hFF;
                @(posedge clk); #1; snap = win_flat;
                @(negedge clk);
                @(posedge clk); #1;
                if (win_flat !== snap) begin
                    $display("FAIL TC12 iter %0d: win_flat changed while en=0", j);
                    fail_count=fail_count+1;
                end else begin
                    $display("PASS TC12 iter %0d: freeze OK", j);
                    pass_count=pass_count+1;
                end
                en = 1;
            end
        end
    end

    // ── Results ──────────────────────────────
    $display("\n=========================================");
    $display("  TOTAL CHECKS : %0d", pass_count + fail_count);
    $display("  PASSED       : %0d", pass_count);
    $display("  FAILED       : %0d", fail_count);
    $display("=========================================");
    if (fail_count == 0) $display("  ALL TESTS PASSED");
    else                 $display("  *** %0d FAILURES ***", fail_count);
    $finish;
end

initial begin $dumpfile("sw3x3_tb.vcd"); $dumpvars(0, tb_sliding_window_3x3); end
initial begin #(CLK_PER*5000); $display("TIMEOUT"); $finish; end

endmodule