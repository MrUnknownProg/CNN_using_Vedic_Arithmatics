module linebuff_3x3 #(
    parameter IMG_W = 28
)(
    input            clk,
    input            rst,
    input            en,
    input      [7:0] pixel_in,

    output reg [7:0] row0,
    output reg [7:0] row1,
    output reg [7:0] row2
);

    reg [7:0] lb1 [0:IMG_W-1];
    reg [7:0] lb2 [0:IMG_W-1];

    integer i;

    always @(posedge clk) begin

        if(rst) begin

            row0 <= 0;
            row1 <= 0;
            row2 <= 0;

            for(i=0;i<IMG_W;i=i+1) begin
                lb1[i] <= 0;
                lb2[i] <= 0;
            end

        end

        else if(en) begin

            for(i=IMG_W-1;i>0;i=i-1) begin
                lb1[i] <= lb1[i-1];
                lb2[i] <= lb2[i-1];
            end

            lb1[0] <= pixel_in;
            lb2[0] <= lb1[IMG_W-1];

            row0 <= pixel_in;
            row1 <= lb1[IMG_W-1];
            row2 <= lb2[IMG_W-1];

        end
    end

endmodule
