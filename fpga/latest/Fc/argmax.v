module argmax(

    input clk,
    input rst,

    input start,

    input signed [31:0] score0,
    input signed [31:0] score1,
    input signed [31:0] score2,
    input signed [31:0] score3,
    input signed [31:0] score4,
    input signed [31:0] score5,
    input signed [31:0] score6,
    input signed [31:0] score7,
    input signed [31:0] score8,
    input signed [31:0] score9,

    output reg [3:0] digit,
    output reg done

);

reg signed [31:0] max_score;

always @(posedge clk)
begin

    if(rst)
    begin
        digit <= 0;
        done  <= 0;
        max_score <= 0;
    end

    else if(start)
    begin

        max_score = score0;
        digit = 0;

        if(score1 > max_score)
        begin
            max_score = score1;
            digit = 1;
        end

        if(score2 > max_score)
        begin
            max_score = score2;
            digit = 2;
        end

        if(score3 > max_score)
        begin
            max_score = score3;
            digit = 3;
        end

        if(score4 > max_score)
        begin
            max_score = score4;
            digit = 4;
        end

        if(score5 > max_score)
        begin
            max_score = score5;
            digit = 5;
        end

        if(score6 > max_score)
        begin
            max_score = score6;
            digit = 6;
        end

        if(score7 > max_score)
        begin
            max_score = score7;
            digit = 7;
        end

        if(score8 > max_score)
        begin
            max_score = score8;
            digit = 8;
        end

        if(score9 > max_score)
        begin
            max_score = score9;
            digit = 9;
        end

        done <= 1;

    end

end

endmodule
