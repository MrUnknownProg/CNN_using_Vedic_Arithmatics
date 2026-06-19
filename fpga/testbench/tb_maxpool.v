`timescale 1ns / 1ps

module tb_maxpool();

    parameter IMG_W  = 6;
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

    //--------------------------------------
    // Clock
    //--------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //--------------------------------------
    // Memories
    //--------------------------------------
    integer i;

    reg signed [DATA_W-1:0] img [0:IMG_W*IMG_W-1];
    reg signed [DATA_W-1:0] expected [0:(IMG_W/2)*(IMG_W/2)-1];

    integer pass, fail;
    integer out_idx;

    //--------------------------------------
    // Print image
    //--------------------------------------
    task print_image;
        integer r,c;
        begin
            $display("\nINPUT IMAGE");

            for(r=0;r<IMG_W;r=r+1) begin
                for(c=0;c<IMG_W;c=c+1)
                    $write("%6d ", img[r*IMG_W+c]);
                $write("\n");
            end
        end
    endtask

    //--------------------------------------
    // Print expected pooled image
    //--------------------------------------
    task print_expected;
        integer r,c;
        begin
            $display("\nEXPECTED POOLED IMAGE");

            for(r=0;r<IMG_W/2;r=r+1) begin
                for(c=0;c<IMG_W/2;c=c+1)
                    $write("%6d ", expected[r*(IMG_W/2)+c]);
                $write("\n");
            end
        end
    endtask

    //--------------------------------------
    // Golden model
    //--------------------------------------
    task compute_expected;

        integer r,c;
        integer idx;

        reg signed [DATA_W-1:0] a,b,c1,d,maxv;

        begin

            idx = 0;

            for(r=0;r<IMG_W;r=r+2) begin
                for(c=0;c<IMG_W;c=c+2) begin

                    a  = img[r*IMG_W + c];
                    b  = img[r*IMG_W + c + 1];
                    c1 = img[(r+1)*IMG_W + c];
                    d  = img[(r+1)*IMG_W + c + 1];

                    maxv = a;
                    if(b  > maxv) maxv = b;
                    if(c1 > maxv) maxv = c1;
                    if(d  > maxv) maxv = d;

                    expected[idx] = maxv;
                    idx = idx + 1;
                end
            end

        end
    endtask

    //--------------------------------------
    // Send image
    //--------------------------------------
    task send_image;
        begin

            for(i=0;i<IMG_W*IMG_W;i=i+1) begin
                @(posedge clk);
                data_in  <= img[i];
                valid_in <= 1'b1;
            end

            @(posedge clk);
            valid_in <= 1'b0;

        end
    endtask

    //--------------------------------------
    // Check outputs
    //--------------------------------------
    task check_output;

        integer watchdog;
        integer r,c;
        integer exp_idx;

        reg signed [DATA_W-1:0] a,b,c1,d,maxv;

        begin

            watchdog = 0;
            exp_idx  = 0;

            wait(valid_out);

            while(exp_idx < (IMG_W/2)*(IMG_W/2) &&
                  watchdog < 500) begin

                @(posedge clk);

                watchdog = watchdog + 1;

                if(valid_out) begin

                    r = (exp_idx/(IMG_W/2))*2;
                    c = (exp_idx%(IMG_W/2))*2;

                    a  = img[r*IMG_W + c];
                    b  = img[r*IMG_W + c + 1];
                    c1 = img[(r+1)*IMG_W + c];
                    d  = img[(r+1)*IMG_W + c + 1];

                    maxv = a;
                    if(b  > maxv) maxv = b;
                    if(c1 > maxv) maxv = c1;
                    if(d  > maxv) maxv = d;

                    $display("");
                    $display("======================================");
                    $display("POOL OUT[%0d]", exp_idx);
                    $display("WINDOW TOPLEFT=(%0d,%0d)", r,c);

                    $display("%6d %6d", a,b);
                    $display("%6d %6d", c1,d);

                    $display("EXPECTED = %0d", maxv);
                    $display("RTL      = %0d", data_out);

                    if(data_out === maxv) begin
                        pass = pass + 1;
                        $display("PASS");
                    end
                    else begin
                        fail = fail + 1;
                        $display("FAIL");
                    end

                    $display("======================================");

                    exp_idx = exp_idx + 1;

                end
            end

            if(watchdog >= 500) begin
                $display("TIMEOUT");
                $finish;
            end

        end
    endtask

    //--------------------------------------
    // Main
    //--------------------------------------
    initial begin

        rst      = 1;
        en       = 0;
        data_in  = 0;
        valid_in = 0;

        pass = 0;
        fail = 0;

        #20;

        rst = 0;
        en  = 1;

        //--------------------------------------------------
        // TC1 : Incrementing
        //--------------------------------------------------
        $display("\n========== TC1 ==========");

        for(i=0;i<IMG_W*IMG_W;i=i+1)
            img[i] = i;

        compute_expected();
        print_image();
        print_expected();

        fork
            send_image();
            check_output();
        join

        //--------------------------------------------------
        // TC2 : Constant
        //--------------------------------------------------
        $display("\n========== TC2 ==========");

        for(i=0;i<IMG_W*IMG_W;i=i+1)
            img[i] = 7;

        compute_expected();
        print_image();
        print_expected();

        fork
            send_image();
            check_output();
        join

        //--------------------------------------------------
        // TC3 : Random
        //--------------------------------------------------
        $display("\n========== TC3 ==========");

        for(i=0;i<IMG_W*IMG_W;i=i+1)
            img[i] = $random % 50;

        compute_expected();
        print_image();
        print_expected();

        fork
            send_image();
            check_output();
        join

        //--------------------------------------------------
        // Summary
        //--------------------------------------------------
        $display("");
        $display("================================");
        $display("PASS = %0d", pass);
        $display("FAIL = %0d", fail);
        $display("================================");

        $finish;

    end

endmodule