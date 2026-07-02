module fc_top(

    input clk,
    input rst,
    input start,

    // Interface to write pooled features into feature memory
    input        feature_we,
    input  [7:0] feature_wr_addr,
    input  signed [19:0] feature_din,

    output [3:0] digit,
    output done

);

    //--------------------------------------------------------
    // Feature Memory <-> FC Engine
    //--------------------------------------------------------
    wire [7:0] feature_addr;
    wire signed [19:0] feature_data;

    feature_mem u_feature_mem(

        .clk(clk),

        .we(feature_we),
        .wr_addr(feature_wr_addr),
        .din(feature_din),

        .rd_addr(feature_addr),
        .dout(feature_data)

    );

    //--------------------------------------------------------
    // Weight ROM <-> FC Engine
    //--------------------------------------------------------
    wire [10:0] weight_addr;
    wire signed [7:0] weight_data;

    fc_weight_rom u_fc_weight_rom(

        .addr(weight_addr),
        .weight(weight_data)

    );

    //--------------------------------------------------------
    // Bias ROM <-> FC Engine
    //--------------------------------------------------------
    wire [3:0] neuron_idx;
    wire signed [15:0] bias_data;

    fc_bias_rom u_fc_bias_rom(

        .addr(neuron_idx),
        .bias(bias_data)

    );

    //--------------------------------------------------------
    // FC Engine <-> Argmax
    //--------------------------------------------------------
    wire engine_done;

    wire signed [31:0] score0;
    wire signed [31:0] score1;
    wire signed [31:0] score2;
    wire signed [31:0] score3;
    wire signed [31:0] score4;
    wire signed [31:0] score5;
    wire signed [31:0] score6;
    wire signed [31:0] score7;
    wire signed [31:0] score8;
    wire signed [31:0] score9;

    fc_engine u_fc_engine(

        .clk(clk),
        .rst(rst),
        .start(start),

        .done(engine_done),

        .feature_addr(feature_addr),
        .feature_data(feature_data),

        .weight_addr(weight_addr),
        .weight_data(weight_data),

        .neuron_idx(neuron_idx),
        .bias_data(bias_data),

        .score0(score0),
        .score1(score1),
        .score2(score2),
        .score3(score3),
        .score4(score4),
        .score5(score5),
        .score6(score6),
        .score7(score7),
        .score8(score8),
        .score9(score9)

    );

    //--------------------------------------------------------
    // Argmax
    //--------------------------------------------------------
    argmax u_argmax(

        .clk(clk),
        .rst(rst),

        .start(engine_done),

        .score0(score0),
        .score1(score1),
        .score2(score2),
        .score3(score3),
        .score4(score4),
        .score5(score5),
        .score6(score6),
        .score7(score7),
        .score8(score8),
        .score9(score9),

        .digit(digit),
        .done(done)

    );

endmodule