module maxpool #(
    parameter IMG_W = 26,
    parameter DATA_W = 20
)(
    input clk,
    input rst,
    input en,

    input  signed [DATA_W-1:0] data_in,
    input                      valid_in,

    output reg signed [DATA_W-1:0] data_out,
    output reg                     valid_out
);

    // line buffer
    reg signed [DATA_W-1:0] linebuf [0:IMG_W-1];

    // column shift registers (VERY IMPORTANT)
    reg signed [DATA_W-1:0] prev_row_pixel;
    reg signed [DATA_W-1:0] prev_cur_pixel;

    reg [7:0] col, row;

    integer i;
    
    reg signed [DATA_W-1:0] curr_row_pixel;
    reg signed [DATA_W-1:0] max_val;

    always @(posedge clk) begin
        if (rst) begin
            col <= 0;
            row <= 0;
            valid_out <= 0;
        end 
        else if (en && valid_in) begin

            // read previous row
            
            curr_row_pixel = linebuf[col];

            // update line buffer
            linebuf[col] <= data_in;

            // form 2x2 window
            // top-left     = prev_row_pixel
            // top-right    = curr_row_pixel
            // bottom-left  = prev_cur_pixel
            // bottom-right = data_in

            if (row > 0 && col > 0 && row[0] && col[0]) begin

                max_val = prev_row_pixel;

                if (curr_row_pixel > max_val) max_val = curr_row_pixel;
                if (prev_cur_pixel > max_val) max_val = prev_cur_pixel;
                if (data_in > max_val)        max_val = data_in;

                data_out  <= max_val;
                valid_out <= 1;
            end 
            else begin
                valid_out <= 0;
            end

            // shift registers (CRITICAL ORDER)
            prev_row_pixel <= curr_row_pixel;
            prev_cur_pixel <= data_in;

            // update indices
            if (col == IMG_W-1) begin
                col <= 0;
                row <= row + 1;
            end else begin
                col <= col + 1;
            end
        end
    end

endmodule