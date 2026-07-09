//`timescale 1ns / 1ps

//module maxpool #(
//    parameter IMG_W = 26,
//    parameter DATA_W = 20
//)(
//    input clk,
//    input rst,
//    input en,

//    input  signed [DATA_W-1:0] data_in,
//    input                      valid_in,

//    output reg signed [DATA_W-1:0] data_out,
//    output reg                     valid_out
//);

//    // BuiltIn Line buffers
//    reg signed [DATA_W-1:0] linebuf [0:IMG_W-1];

//    reg signed [DATA_W-1:0] prev_row_pixel;
//    reg signed [DATA_W-1:0] prev_cur_pixel;

//    reg [7:0] col, row;

//    integer i;

//    reg signed [DATA_W-1:0] max_val;

//    wire signed [DATA_W-1:0] curr_row_pixel;
//    assign curr_row_pixel = linebuf[col];

//    always @(posedge clk) begin
//        if (rst) begin
//            col <= 0;
//            row <= 0;
//            valid_out <= 0;

//            prev_row_pixel <= 0;
//            prev_cur_pixel <= 0;

//            for (i = 0; i < IMG_W; i = i + 1)
//                linebuf[i] <= 0;
//        end 
//        else if (en) begin

//            valid_out <= 0;

//            if (valid_in) begin

//                // 🔥 FIX: clear shift registers at start of row
//                if (col == 0) begin
//                    prev_row_pixel <= 0;
//                    prev_cur_pixel <= 0;
//                end

//                // compute window
//                if (row > 0 && col > 0 && row[0] && col[0]) begin
//                    max_val = prev_row_pixel;

//                    if (curr_row_pixel > max_val) max_val = curr_row_pixel;
//                    if (prev_cur_pixel > max_val) max_val = prev_cur_pixel;
//                    if (data_in > max_val)        max_val = data_in;

//                    data_out  <= max_val;
//                    valid_out <= 1;
//                end

//                // update buffer AFTER read
//                linebuf[col] <= data_in;

//                // shift registers
//                prev_row_pixel <= curr_row_pixel;
//                prev_cur_pixel <= data_in;

//                // index update
//                if (col == IMG_W-1) begin
//                    col <= 0;
//                    row <= row + 1;
//                end else begin
//                    col <= col + 1;
//                end
//            end
//        end
//    end

//endmodule


module maxpool #(
    parameter IMG_W  = 26,
    parameter DATA_W = 20
)(
    input clk,
    input rst,
    input en,

    input signed [DATA_W-1:0] row0_in,   // current row
    input signed [DATA_W-1:0] row1_in,   // previous row

    output reg signed [DATA_W-1:0] data_out,
    output reg valid_out
);

    reg signed [DATA_W-1:0] row0_prev;
    reg signed [DATA_W-1:0] row1_prev;

    reg [7:0] col, col_d;
    reg [7:0] row, row_d;

    always @(posedge clk) begin

        if(rst) begin
            row0_prev <= 0;
            row1_prev <= 0;

            row <= 0;
            col <= 0;

            data_out <= 0;
            valid_out <= 0;
        end
        else if(en) begin

            valid_out <= 0;
            
            col_d <=col;
            row_d <= row;
            
            // Generate pooled output on odd row/odd col
            if(row_d > 0 && col_d > 0 &&
               row_d[0] == 1'b1 &&
               col_d[0] == 1'b1) begin
                
//                $display("MAX=%0d",
//        max_of_4(
//            row0_prev,
//            row0_in,
//            row1_prev,
//            row1_in
//        ));
                
                data_out <= max_of_4(
                    row0_prev,  // top-left
                    row0_in,    // top-right
                    row1_prev,  // bottom-left
                    row1_in     // bottom-right
                );

//                $display("DATA_OUT_NOW=%0d", data_out);

                valid_out <= 1'b1;
            end

            // Store previous column values
            row0_prev <= row0_in;
            row1_prev <= row1_in;

            // Update coordinates
            if(col == IMG_W-1) begin
                col <= 0;
                row <= row + 1;

                row0_prev <= 0;
                row1_prev <= 0;
            end
            else begin
                col <= col + 1;
            end

        end
    end

    function signed [DATA_W-1:0] max_of_4;
        input signed [DATA_W-1:0] a;
        input signed [DATA_W-1:0] b;
        input signed [DATA_W-1:0] c;
        input signed [DATA_W-1:0] d;

        reg signed [DATA_W-1:0] t1;
        reg signed [DATA_W-1:0] t2;

        begin
            t1 = (a > b) ? a : b;
            t2 = (c > d) ? c : d;
            max_of_4 = (t1 > t2) ? t1 : t2;
        end
    endfunction

endmodule
