module fc_engine(

    input clk,
    input rst,
    input start,

    output reg done,

    // Feature Memory
    output reg [7:0] feature_addr,
    input signed [19:0] feature_data,

    // Weight ROM
    output reg [10:0] weight_addr,
    input signed [7:0] weight_data,

    // Bias ROM
    output reg [3:0] neuron_idx,
    input signed [15:0] bias_data,

    // FC Scores
    output reg signed [31:0] score0,
    output reg signed [31:0] score1,
    output reg signed [31:0] score2,
    output reg signed [31:0] score3,
    output reg signed [31:0] score4,
    output reg signed [31:0] score5,
    output reg signed [31:0] score6,
    output reg signed [31:0] score7,
    output reg signed [31:0] score8,
    output reg signed [31:0] score9

);

localparam IDLE  = 2'd0;
localparam CALC  = 2'd1;
localparam STORE = 2'd2;
localparam DONE  = 2'd3;

reg [1:0] state;

reg [7:0] feature_idx;
reg signed [31:0] acc;

always @(posedge clk)
begin

    if(rst)
    begin

        state <= IDLE;

        feature_idx <= 0;
        neuron_idx  <= 0;

        feature_addr <= 0;
        weight_addr  <= 0;

        acc  <= 0;
        done <= 0;

        score0 <= 0;
        score1 <= 0;
        score2 <= 0;
        score3 <= 0;
        score4 <= 0;
        score5 <= 0;
        score6 <= 0;
        score7 <= 0;
        score8 <= 0;
        score9 <= 0;

    end

    else
    begin

        case(state)

        //--------------------------------------------------
        // IDLE
        //--------------------------------------------------
        IDLE:
        begin

            done <= 0;

            if(start)
            begin

                feature_idx <= 0;
                neuron_idx  <= 0;

                feature_addr <= 0;
                weight_addr  <= 0;

                acc <= 0;

                state <= CALC;

            end

        end

        //--------------------------------------------------
        // CALC
        //--------------------------------------------------
        CALC:
        begin

            feature_addr <= feature_idx;

            weight_addr <=
                neuron_idx * 169 +
                feature_idx;

            acc <= acc +
                   ($signed(feature_data) *
                    $signed(weight_data));
                    
                  if(neuron_idx == 0 &&
   feature_idx >= 15 &&
   feature_idx <= 22)
begin

    $display(
    "F=%0d FEAT=%0d WADDR=%0d W=%0d ACC=%0d",
    feature_idx,
    feature_data,
    weight_addr,
    weight_data,
    acc
    );

end  

     if(feature_idx == 8'd168)
            begin
                state <= STORE;
            end
            else
            begin
                feature_idx <= feature_idx + 1;
            end

        end

        //--------------------------------------------------
        // STORE
        //--------------------------------------------------
        STORE:
        begin
        $display("NEURON=%0d ACC=%0d BIAS=%0d SCORE=%0d",
         neuron_idx,
         acc,
         bias_data,
         acc + bias_data);

            case(neuron_idx)

                0: score0 <= acc + bias_data;
                1: score1 <= acc + bias_data;
                2: score2 <= acc + bias_data;
                3: score3 <= acc + bias_data;
                4: score4 <= acc + bias_data;
                5: score5 <= acc + bias_data;
                6: score6 <= acc + bias_data;
                7: score7 <= acc + bias_data;
                8: score8 <= acc + bias_data;
                9: score9 <= acc + bias_data;

            endcase

            if(neuron_idx == 4'd9)
            begin
                state <= DONE;
            end
            else
            begin

                neuron_idx <= neuron_idx + 1;

                feature_idx <= 0;

                feature_addr <= 0;

                weight_addr <=
                    (neuron_idx + 1) * 169;

                acc <= 0;

                state <= CALC;

            end

        end

        //--------------------------------------------------
        // DONE
        //--------------------------------------------------
        DONE:
        begin
            done <= 1;
        end

        endcase

    end

end

endmodule