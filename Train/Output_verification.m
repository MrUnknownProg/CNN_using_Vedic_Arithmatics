clear; clc; close all;

%% ================= LOAD MODEL =================
load('trained_net.mat');   % contains 'net'

%% ================= LOAD DATA =================
mn = load("mnist.mat");

XTest  = mn.digits_test;
YTest  = mn.labels_test;

XTest = reshape(XTest, 28, 28, 1, []);
XTest = single(XTest) / 255;

idx = 5000;   % MUST match RTL
input_img = XTest(:,:,:,idx);

fprintf("Verifying sample %d (label = %d)\n", idx, YTest(idx));

%% ================= EXTRACT KERNEL =================
convLayer = net.Layers(2);

kernel = squeeze(convLayer.Weights);   % 3x3

% SAME SCALE AS RTL EXPORT
max_val = max(abs(kernel(:)));
if max_val == 0
    SCALE = 1;
else
    SCALE = 127 / max_val;
end

kernel_q = int8(round(kernel * SCALE));

%% ================= QUANTIZE INPUT =================
img_q = int8(round(input_img * 127));   % SAME AS RTL

%% ================= CONVOLUTION (FIXED-POINT) =================
conv_out = zeros(26,26, 'int32');

for i = 1:26
    for j = 1:26
        window = int32(img_q(i:i+2, j:j+2));
        w      = int32(kernel_q);

        conv_out(i,j) = sum(window(:) .* w(:));
    end
end

%% ================= RELU =================
conv_out(conv_out < 0) = 0;

%% ================= MAXPOOL (2x2, stride=2) =================
pool_out = zeros(13,13, 'int32');

for i = 1:13
    for j = 1:13
        block = conv_out(2*i-1:2*i, 2*j-1:2*j);
        pool_out(i,j) = max(block(:));
    end
end

matlab_map = pool_out;

%% ================= LOAD RTL OUTPUT =================
fid = fopen("pool_output.txt","r");
data = textscan(fid, '%d : %d');
fclose(fid);

rtl_vals = int32(data{2});

if length(rtl_vals) ~= 169
    error("RTL output size mismatch!");
end

rtl_map = reshape(rtl_vals,13,13);
%rtl_map = reshape(rtl_vals, [13 13]);
%rtl2 = reshape(rtl_vals,13,13);
% %rtl2 = flipud(reshape(rtl_vals,13,13).');
% rtl2 = fliplr(reshape(rtl_vals,13,13).');
% rtl2 = rot90(reshape(rtl_vals,13,13).');

%% ================= ALIGNMENT CHECK =================
rtl_map_T = rtl_map';

err1 = max(abs(matlab_map(:) - rtl_map(:)));
err2 = max(abs(matlab_map(:) - rtl_map_T(:)));

if err2 < err1
    rtl_map = rtl_map_T;
    fprintf("Using TRANSPOSED alignment\n");
else
    fprintf("Using DIRECT alignment\n");
end

%% ================= ERROR =================
diff = matlab_map - rtl_map;

max_err  = max(abs(diff(:)));
mean_err = mean(abs(diff(:)));

fprintf("\n=== VERIFICATION RESULTS ===\n");
fprintf("Max Error  = %d\n", max_err);
fprintf("Mean Error = %.2f\n", mean_err);

if max_err == 0
    fprintf("PERFECT MATCH\n");
elseif max_err <= 5
    fprintf("PASS (quantization difference)\n");
else
    fprintf("FAIL → check RTL\n");
end

%% ================= VISUAL =================
figure;

subplot(1,3,1)
imagesc(matlab_map);
title("MATLAB (Fixed-Point)");
colorbar; axis image;

subplot(1,3,2)
imagesc(rtl_map);
title("RTL Output");
colorbar; axis image;

subplot(1,3,3)
imagesc(diff);
title("DIFFERENCE");
colorbar; axis image;

%% ================= DEBUG PRINT =================
fprintf("\nSample comparison:\n");
for i = 1:10
    fprintf("MATLAB=%6d  RTL=%6d  DIFF=%4d\n", ...
        matlab_map(i), rtl_map(i), diff(i));
end





































































% %% ================= FC TEST USING RTL =================
% 
% % -------- ENSURE RTL MAP EXISTS --------
% if ~exist('rtl_map','var')
%     error("rtl_map not found. Ensure RTL loading section executed correctly.");
% end
% 
% if ~exist('matlab_map','var')
%     error("matlab_map not found. Ensure MATLAB pipeline executed.");
% end
% 
% % -------- FLATTEN --------
% rtl_vec = double(rtl_map(:));
% matlab_vec = double(matlab_map(:));
% 
% % -------- NORMALIZE (IMPORTANT) --------
% % Bring values to similar dynamic range as training
% scale_fc = max(abs(matlab_vec));
% if scale_fc == 0
%     scale_fc = 1;
% end
% 
% rtl_vec = rtl_vec / scale_fc;
% matlab_vec = matlab_vec / scale_fc;
% 
% % -------- EXTRACT FC LAYER FROM NET --------
% % Adjust index if your FC layer is at different position
% fcLayer = [];
% 
% for k = 1:length(net.Layers)
%     if contains(class(net.Layers(k)), 'FullyConnected')
%         fcLayer = net.Layers(k);
%         break;
%     end
% end
% 
% if isempty(fcLayer)
%     error("No Fully Connected layer found in network!");
% end
% 
% W_fc = double(fcLayer.Weights);   % [numClasses x features]
% b_fc = double(fcLayer.Bias);
% 
% % -------- CHECK SIZE MATCH --------
% if size(W_fc,2) ~= length(rtl_vec)
%     error("FC input size mismatch! Expected %d, got %d", size(W_fc,2), length(rtl_vec));
% end
% 
% % -------- FC COMPUTATION --------
% fc_rtl = W_fc * rtl_vec + b_fc;
% fc_mat = W_fc * matlab_vec + b_fc;
% 
% % -------- SOFTMAX (for classification clarity) --------
% softmax = @(x) exp(x) ./ sum(exp(x));
% 
% prob_rtl = softmax(fc_rtl);
% prob_mat = softmax(fc_mat);
% 
% % -------- PREDICTIONS --------
% [~, pred_rtl] = max(prob_rtl);
% [~, pred_mat] = max(prob_mat);
% 
% fprintf("\n=== FC RESULTS ===\n");
% fprintf("MATLAB Prediction = %d\n", pred_mat-1);
% fprintf("RTL Prediction    = %d\n", pred_rtl-1);
% 
% % -------- ERROR --------
% fc_err = norm(fc_rtl - fc_mat);
% 
% fprintf("FC L2 Error = %.6f\n", fc_err);
% 
% % -------- VISUALIZE FC OUTPUT --------
% %% -------- PLOT WITH DIGIT AXIS (0–9) --------
% classes = 0:9;
% 
% figure;
% 
% subplot(1,2,1)
% stem(classes, prob_mat, 'filled');
% title('MATLAB FC Output (Softmax)');
% xlabel('Digit'); ylabel('Probability');
% xticks(classes);
% 
% subplot(1,2,2)
% stem(classes, prob_rtl, 'filled');
% title('RTL FC Output (Softmax)');
% xlabel('Digit'); ylabel('Probability');
% xticks(classes);
% 
% % -------- FINAL INTERPRETATION --------
% if pred_rtl == pred_mat
%     fprintf("FC RESULT: MATCH (RTL still usable)\n");
% else
%     fprintf("FC RESULT: MISMATCH (RTL features corrupted)\n");
% end