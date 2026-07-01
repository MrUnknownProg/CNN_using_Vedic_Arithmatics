clear; clc; close all;

%% ================= LOAD MNIST =================
mn = load("mnist.mat");
XTrain = mn.digits_train;
YTrain = mn.labels_train;
XTest  = mn.digits_test;
YTest  = mn.labels_test;

% Reshape
XTrain = reshape(XTrain, 28, 28, 1, []);
XTest  = reshape(XTest,  28, 28, 1, []);

% Normalize (float for training)
XTrain = single(XTrain) / 255;
XTest  = single(XTest)  / 255;

YTrain = categorical(YTrain);
YTest  = categorical(YTest);

fprintf("MNIST loaded successfully.\n");


%% ================= EXPORT IMAGE =================

idx = 5624;   % change index if needed

img = XTest(:,:,:,idx);

% input_img = zeros(28,28,'single');
% input_img(14,14) = 1;   % center impulse

% Convert to SIGNED input (matches RTL)
img_q = int8(round(img * 127));

fid = fopen('image3.mem', 'w');

for i = 1:28
    for j = 1:28
        val = typecast(int8(img_q(i,j)), 'uint8');
        fprintf(fid, '%s\n', dec2bin(val, 8));
    end
end

fclose(fid);

fprintf("image.mem exported (SIGNED INPUT)\n");
fprintf("Label = %s\n", string(YTest(idx)));

%==========================================================
%           Straight line
%==========================================================


% clc;
% clear;
% 
% img = zeros(28,28,'int8');
% 
% % Center vertical line (column 15 in MATLAB = column 14 in 0-based indexing)
% img(:,15) = 127;
% 
% fid = fopen('image_line.mem','w');
% 
% for r = 1:28
%     for c = 1:28
%         val = typecast(int8(img(r,c)),'uint8');
%         fprintf(fid,'%08s\n',dec2bin(val,8));
%     end
% end
% 
% fclose(fid);
% 
% disp('image.mem generated successfully.');