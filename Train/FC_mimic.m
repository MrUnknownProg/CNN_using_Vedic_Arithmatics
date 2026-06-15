clc;
clear;
close all;

%% =====================================================
%% LOAD TRAINED NETWORK
%% =====================================================

load('trained_net.mat');   % contains variable: net

%% =====================================================
%% LOAD RTL POOL OUTPUT
%% =====================================================

fid = fopen('pool_output.txt','r');

if fid == -1
    error('Cannot open file. Check the name.');
end

data = textscan(fid,'%d : %d');

fclose(fid);

pool_vals = double(data{2});

if length(pool_vals) ~= 169
    error('Expected 169 pooled values, found %d',length(pool_vals));
end

fprintf('Loaded %d pooled features\n',length(pool_vals));

%% =====================================================
%% FC INPUT VECTOR
%% =====================================================

fc_input = pool_vals(:);

%% =====================================================
%% EXTRACT FC LAYER
%% =====================================================

fcLayer = [];

for k = 1:length(net.Layers)

    if isa(net.Layers(k), ...
        'nnet.cnn.layer.FullyConnectedLayer')

        fcLayer = net.Layers(k);
        break;
    end

end

if isempty(fcLayer)
    error('Fully Connected layer not found');
end

W = double(fcLayer.Weights);   % [10 x 169]
B = double(fcLayer.Bias(:));   % [10 x 1]

%% =====================================================
%% SIZE CHECK
%% =====================================================

if size(W,2) ~= length(fc_input)

    error(['FC input size mismatch. ' ...
           'Expected %d features, got %d'], ...
           size(W,2), length(fc_input));

end

%% =====================================================
%% FULLY CONNECTED LAYER
%% =====================================================

logits = W * fc_input + B;

%% =====================================================
%% NUMERICALLY STABLE SOFTMAX
%% =====================================================

logits_shift = logits - max(logits);

exp_scores = exp(logits_shift);

prob = exp_scores ./ sum(exp_scores);

%% =====================================================
%% ARGMAX PREDICTION
%% =====================================================

[confidence, idx] = max(prob);

prediction = idx - 1;   % digits are 0..9

%% =====================================================
%% RESULTS
%% =====================================================

fprintf('\n');
fprintf('=====================================\n');
fprintf('CNN PREDICTION RESULT\n');
fprintf('=====================================\n');
fprintf('Predicted Digit : %d\n', prediction);
fprintf('Confidence      : %.4f %%\n', confidence*100);
fprintf('=====================================\n');

%% =====================================================
%% PRINT ALL CLASS PROBABILITIES
%% =====================================================

fprintf('\nDigit Probabilities:\n');
fprintf('----------------------------\n');

for d = 0:9

    fprintf('Digit %d : %8.4f %%\n', ...
        d, prob(d+1)*100);

end

%% =====================================================
%% BAR GRAPH
%% =====================================================

figure;

bar(0:9, prob*100);

xlabel('Digit');
ylabel('Probability (%)');
title('Softmax Output');

xticks(0:9);
grid on;

%% =====================================================
%% SHOW TOP-3 PREDICTIONS
%% =====================================================

[sortedProb, sortedIdx] = sort(prob,'descend');

fprintf('\nTop 3 Predictions\n');
fprintf('----------------------------\n');

for k = 1:3

    fprintf('#%d  Digit %d  --> %.4f %%\n', ...
        k, ...
        sortedIdx(k)-1, ...
        sortedProb(k)*100);

end