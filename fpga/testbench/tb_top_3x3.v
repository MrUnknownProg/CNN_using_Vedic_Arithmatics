`timescale 1ns/1ps
module tb_top_3x3;

    parameter IMG_W      = 28;
    parameter OUT_W      = 26;
    parameter POOL_W     = OUT_W / 2;          // ✅ NEW
    parameter TOTAL_POOL = POOL_W * POOL_W;    // ✅ NEW
    parameter CLK_PER    = 10;

    // latency unchanged (conv pipeline)
    parameter FILL_LATENCY = 2*IMG_W + 4;

    reg         clk, rst, en;
    reg  [12:0] rd_addr;
    reg         rd_en;
    wire [19:0] rd_data;

    top_3x3 #(.IMG_W(IMG_W),.OUT_W(OUT_W)) dut (
        .clk(clk),.rst(rst),.en(en),
        .rd_addr(rd_addr),.rd_en(rd_en),
        .rd_data(rd_data)
    );

    always #(CLK_PER/2) clk = ~clk;

    integer i, pass_count, fail_count;

    // RESET
    task do_reset;
        begin
            @(negedge clk); rst=1; en=0;
            repeat(4) @(posedge clk);

            // clear pooled memory
            for (i=0; i<TOTAL_POOL; i=i+1)
                dut.pool_bram[i] = 0;

            dut.pool_idx = 0;
            dut.img_addr = 0;

            @(negedge clk); rst=0;
        end
    endtask

    // RUN
    task run_pipeline;
        begin
            en=1;
            repeat(IMG_W*IMG_W + 200) @(posedge clk);  // extra cycles for pooling
            en=0;
            repeat(4) @(posedge clk);
        end
    endtask

    // READ pooled output
    task read_pool;
        input  [12:0] addr;
        output [19:0] data;
        begin
            @(negedge clk);
            rd_addr = addr;
            rd_en   = 1;
            @(posedge clk); #1;
            data = rd_data;
            rd_en = 0;
        end
    endtask

    reg [19:0] rdata;
    integer bad;

    initial begin
        clk=0; rst=1; en=0; rd_addr=0; rd_en=0;
        pass_count=0; fail_count=0;

        $display("=== CONV + MAXPOOL TEST ===");
        $display("IMG=%0d  CONV_OUT=%0d  POOL_OUT=%0d", IMG_W, OUT_W, POOL_W);

        // ── TC1 ──
        $display("\n--- TC1: ones → expected=9 ---");
        for (i=0; i<IMG_W*IMG_W; i=i+1) dut.img_bram[i]=8'd1;
        for (i=0; i<9; i=i+1) dut.weight_bram[i]=8'd1;

        do_reset();
        run_pipeline();

        bad=0;
        for (i=0; i<TOTAL_POOL; i=i+1) begin
            read_pool(i, rdata);
            if (rdata !== 20'd9) begin
                if (bad<5) $display("FAIL[%0d]: %0d", i, rdata);
                bad=bad+1; fail_count=fail_count+1;
            end else pass_count=pass_count+1;
        end

        // ── TC2 ──
        $display("\n--- TC2: twos → expected=18 ---");
        for (i=0; i<IMG_W*IMG_W; i=i+1) dut.img_bram[i]=8'd2;
        for (i=0; i<9; i=i+1) dut.weight_bram[i]=8'd1;

        do_reset();
        run_pipeline();

        bad=0;
        for (i=0; i<TOTAL_POOL; i=i+1) begin
            read_pool(i, rdata);
            if (rdata !== 20'd18) begin
                if (bad<5) $display("FAIL[%0d]: %0d", i, rdata);
                bad=bad+1; fail_count=fail_count+1;
            end else pass_count=pass_count+1;
        end

        // ── TC3 ──
        $display("\n--- TC3: zero kernel → expected=0 ---");
        for (i=0; i<IMG_W*IMG_W; i=i+1) dut.img_bram[i]=8'd1;
        for (i=0; i<9; i=i+1) dut.weight_bram[i]=8'd0;

        do_reset();
        run_pipeline();

        for (i=0; i<TOTAL_POOL; i=i+1) begin
            read_pool(i, rdata);
            if (rdata !== 20'd0)
                fail_count=fail_count+1;
            else
                pass_count=pass_count+1;
        end

        // ── TC4 ──
        $display("\n--- TC4: max pixel → expected=2295 ---");
        for (i=0; i<IMG_W*IMG_W; i=i+1) dut.img_bram[i]=8'hFF;
        for (i=0; i<9; i=i+1) dut.weight_bram[i]=8'd1;

        do_reset();
        run_pipeline();

        for (i=0; i<TOTAL_POOL; i=i+1) begin
            read_pool(i, rdata);
            if (rdata !== 20'd2295)
                fail_count=fail_count+1;
            else
                pass_count=pass_count+1;
        end

        // RESULT
        $display("\n==============================");
        $display("PASS=%0d FAIL=%0d", pass_count, fail_count);
        $display("==============================");

        $finish;
    end

endmodule