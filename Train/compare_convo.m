clc;
clear;
close all;

%% =====================================================
%% LOAD IMAGE.MEM
%% =====================================================

fid = fopen('image.mem','r');

if fid == -1
    error('Cannot open image.mem');
end

img_vec = [];

while ~feof(fid)

    line = strtrim(fgetl(fid));

    if isempty(line)
        continue;
    end

    img_vec(end+1) = bin2dec(line);

end

fclose(fid);

img_vec(img_vec >= 128) = img_vec(img_vec >= 128) - 256;

fprintf('Image values loaded  : %d\n', length(img_vec));

if length(img_vec) ~= 784
    error('Expected 784 image values');
end

img_q = reshape(int32(img_vec),28,28).';

%% =====================================================
%% IMAGE VERIFICATION
%% =====================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('IMAGE VERIFICATION\n');
fprintf('============================================================\n');

%% Top Left

fprintf('\nTOP LEFT 8x8 BLOCK\n');
fprintf('------------------------------------------------------------\n');
disp(img_q(1:8,1:8));

%% Center Region

fprintf('\nCENTER 10x10 BLOCK\n');
fprintf('------------------------------------------------------------\n');
disp(img_q(10:19,10:19));

%% Non-Zero Statistics

nz = find(img_q ~= 0);

fprintf('\n');
fprintf('============================================================\n');
fprintf('NON-ZERO PIXEL STATISTICS\n');
fprintf('============================================================\n');

fprintf('Total Pixels     : %d\n', numel(img_q));
fprintf('Non-Zero Pixels  : %d\n', length(nz));
fprintf('Zero Pixels      : %d\n', numel(img_q)-length(nz));

%% Pixel Counters

neg_count  = sum(img_q(:) < 0);
zero_count = sum(img_q(:) == 0);
pos_count  = sum(img_q(:) > 0);

fprintf('\n');
fprintf('============================================================\n');
fprintf('PIXEL VALUE COUNTERS\n');
fprintf('============================================================\n');

fprintf('Negative Pixels : %d\n', neg_count);
fprintf('Zero Pixels     : %d\n', zero_count);
fprintf('Positive Pixels : %d\n', pos_count);

%% Bounding Box

if ~isempty(nz)

    [rows, cols] = ind2sub(size(img_q), nz);

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('DIGIT BOUNDING BOX\n');
    fprintf('============================================================\n');

    fprintf('Min Row : %d\n', min(rows)-1);
    fprintf('Max Row : %d\n', max(rows)-1);

    fprintf('Min Col : %d\n', min(cols)-1);
    fprintf('Max Col : %d\n', max(cols)-1);

end

%% First 100 Non-Zero Pixels

fprintf('\n');
fprintf('============================================================\n');
fprintf('FIRST 100 NON-ZERO PIXELS\n');
fprintf('============================================================\n');

fprintf('%-6s %-6s %-8s\n', 'ROW','COL','PIX');
fprintf('%s\n', repmat('-',1,25));

for k = 1:min(100,length(nz))

    [r,c] = ind2sub(size(img_q), nz(k));

    fprintf('%-6d %-6d %-8d\n', ...
        r-1, ...
        c-1, ...
        img_q(r,c));

end

%% Window Around First Mismatch Location

fprintf('\n');
fprintf('============================================================\n');
fprintf('WINDOW @ ROW=3 COL=11\n');
fprintf('============================================================\n');

r = 4;      % MATLAB index for RTL row=3
c = 12;     % MATLAB index for RTL col=11

disp(img_q(r:r+2,c:c+2));

%% =====================================================
%% LOAD WEIGHTS.MEM
%% =====================================================

fid = fopen('weights.mem','r');

if fid == -1
    error('Cannot open weights.mem');
end

w_vec = [];

while ~feof(fid)

    line = strtrim(fgetl(fid));

    if isempty(line)
        continue;
    end

    w_vec(end+1) = bin2dec(line);

end

fclose(fid);

w_vec(w_vec >= 128) = w_vec(w_vec >= 128) - 256;

fprintf('Weight values loaded : %d\n', length(w_vec));

if length(w_vec) ~= 9
    error('Expected 9 kernel values');
end

kernel_q = reshape(int32(w_vec),3,3).';

fprintf('\nKERNEL FROM WEIGHTS.MEM\n');
disp(kernel_q);
%% =====================================================
%% MATLAB CONV + RELU
%% =====================================================

conv_ref = zeros(26,26,'int32');

for r = 1:26

    for c = 1:26

        win = img_q(r:r+2,c:c+2);

        s = sum(int32(win(:)) .* int32(kernel_q(:)));

        conv_ref(r,c) = max(s,0);

    end

end

mat_vals = conv_ref(:);

%% =====================================================
%% LOAD RTL OUTPUT
%% =====================================================

fid = fopen('conv_output.txt','r');

if fid == -1
    error('Cannot open conv_output.txt');
end

rtl_vals = [];

while ~feof(fid)

    line = strtrim(fgetl(fid));

    tok = regexp(line,'^\d+\s*:\s*(-?\d+)$','tokens');

    if ~isempty(tok)
        rtl_vals(end+1) = str2double(tok{1}{1});
    end

end

fclose(fid);

%% =====================================================
%% PIPELINE SHIFT CHECK
%% =====================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('PIPELINE SHIFT CHECK\n');
fprintf('============================================================\n');

for shift = 0:10

    if length(rtl_vals) >= length(mat_vals)+shift

        rtl_tmp = rtl_vals(1+shift : length(mat_vals)+shift);

        err_tmp = double(mat_vals) - double(rtl_tmp);

        matches_tmp = sum(err_tmp == 0);

        fprintf('SHIFT = %2d --> MATCHES = %3d / %3d (%.2f%%)\n', ...
            shift, ...
            matches_tmp, ...
            length(mat_vals), ...
            100*matches_tmp/length(mat_vals));

    end

end

%% =====================================================
%% SUMMARY
%% =====================================================

mat_count = length(mat_vals);
rtl_count = length(rtl_vals);

N = min(mat_count, rtl_count);

fprintf('\n');
fprintf('============================================================\n');
fprintf('                 CONV + RELU VERIFICATION\n');
fprintf('============================================================\n');

fprintf('MATLAB Outputs : %d\n', mat_count);
fprintf('RTL Outputs    : %d\n', rtl_count);
fprintf('Compared       : %d\n', N);

if mat_count == rtl_count
    fprintf('Count Status   : PASS\n');
else
    fprintf('Count Status   : FAIL\n');
    fprintf('Difference     : %d\n', abs(mat_count - rtl_count));
end

% =====================================================
% COMPARISON
% =====================================================

mat_cmp = double(mat_vals(1:N));
rtl_cmp = double(rtl_vals(1:N));

err = mat_cmp - rtl_cmp;

matches    = sum(err == 0);
mismatches = sum(err ~= 0);

% fprintf('\n');
% fprintf('Matches        : %d\n', matches);
% fprintf('Mismatches     : %d\n', mismatches);
% fprintf('Match %%         : %.2f %%\n', 100*matches/N);

% if ~isempty(err)
%     fprintf('Max Error      : %d\n', max(abs(err)));
%     fprintf('Mean Error     : %.2f\n', mean(abs(err)));
% end

%% =====================================================
%% FIRST MISMATCH
%% =====================================================

first_bad = find(err ~= 0,1);

if isempty(first_bad)

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('PASS : PERFECT MATCH\n');
    fprintf('============================================================\n');

else

    row = floor((first_bad-1)/26);
    col = mod(first_bad-1,26);

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('FIRST MISMATCH\n');
    fprintf('============================================================\n');

    fprintf('IDX    : %d\n', first_bad-1);
    fprintf('ROW    : %d\n', row);
    fprintf('COL    : %d\n', col);
    fprintf('MATLAB : %d\n', mat_vals(first_bad));
    fprintf('RTL    : %d\n', rtl_vals(first_bad));
    fprintf('DIFF   : %d\n', mat_vals(first_bad)-rtl_vals(first_bad));

end

% %% =====================================================
% %% ALL MISMATCHES
% %% =====================================================
% 
% diff_idx = find(err ~= 0);
% 
% fprintf('\n');
% fprintf('============================================================\n');
% fprintf('ALL MISMATCHES\n');
% fprintf('============================================================\n');
% 
% if isempty(diff_idx)
% 
%     fprintf('No mismatches found.\n');
% 
% else
% 
%     fprintf('\n');
%     fprintf('%-6s %-4s %-4s %-12s %-12s %-12s\n', ...
%         'IDX','ROW','COL','MATLAB','RTL','DIFF');
% 
%     fprintf('%s\n', repmat('-',1,65));
% 
%     for k = 1:length(diff_idx)
% 
%         idx = diff_idx(k);
% 
%         if idx > N
%             continue;
%         end
% 
%         row = floor((idx-1)/26);
%         col = mod(idx-1,26);
% 
%         fprintf('%-6d %-4d %-4d %-12d %-12d %-12d\n', ...
%             idx-1, ...
%             row, ...
%             col, ...
%             mat_vals(idx), ...
%             rtl_vals(idx), ...
%             mat_vals(idx)-rtl_vals(idx));
% 
%     end
% 
% end

%% =====================================================
%% FULL COMPARISON TABLE
%% =====================================================

fprintf('\n');
fprintf('====================================================================================\n');
fprintf('FULL COMPARISON TABLE\n');
fprintf('====================================================================================\n');

fprintf('%-6s %-4s %-4s %-12s %-12s %-12s %-8s\n', ...
    'IDX','ROW','COL','MATLAB','RTL','DIFF','STATUS');

fprintf('%s\n', repmat('-',1,90));

ok_count   = 0;
fail_count = 0;

for idx = 1:N

    row = floor((idx-1)/26);
    col = mod(idx-1,26);

    diff_val = mat_vals(idx) - rtl_vals(idx);

    if diff_val == 0

    status = '[OK]';
    ok_count = ok_count + 1;

else

    status = '[XX]';
    fail_count = fail_count + 1;

end

    fprintf('%-6d %-4d %-4d %-12d %-12d %-12d %-8s\n', ...
        idx-1, ...
        row, ...
        col, ...
        mat_vals(idx), ...
        rtl_vals(idx), ...
        diff_val, ...
        status);

end

%% =====================================================
%% DEBUG WINDOW AROUND FIRST ERROR
%% =====================================================

% if ~isempty(first_bad)
% 
%     fprintf('\n');
%     fprintf('============================================================\n');
%     fprintf('DEBUG WINDOW (±10)\n');
%     fprintf('============================================================\n');
% 
%     start_idx = max(1, first_bad-10);
%     end_idx   = min(N, first_bad+10);
% 
%     fprintf('\n');
%     fprintf('%-6s %-12s %-12s %-12s\n', ...
%         'IDX','MATLAB','RTL','DIFF');
% 
%     fprintf('%s\n', repmat('-',1,50));
% 
%     for idx = start_idx:end_idx
% 
%         diff_val = mat_vals(idx)-rtl_vals(idx);
% 
%         if idx == first_bad
% 
%             fprintf('>%4d %-12d %-12d %-12d\n', ...
%                 idx-1, ...
%                 mat_vals(idx), ...
%                 rtl_vals(idx), ...
%                 diff_val);
% 
%         else
% 
%             fprintf(' %4d %-12d %-12d %-12d\n', ...
%                 idx-1, ...
%                 mat_vals(idx), ...
%                 rtl_vals(idx), ...
%                 diff_val);
% 
%         end
% 
%     end
% 
% end

%% =====================================================
%% MISSING RTL OUTPUTS
%% =====================================================

if mat_count > rtl_count

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('MISSING RTL OUTPUTS\n');
    fprintf('============================================================\n');

    for idx = rtl_count+1 : mat_count

        row = floor((idx-1)/26);
        col = mod(idx-1,26);

        fprintf('IDX=%3d  ROW=%2d  COL=%2d  MATLAB=%d\n', ...
            idx-1, ...
            row, ...
            col, ...
            mat_vals(idx));

    end

end

fprintf('[OK] Matches    : %d\n', ok_count);
fprintf('[XX] Mismatches : %d\n', fail_count);

%% =====================================================
%% EXTRA RTL OUTPUTS
%% =====================================================

if rtl_count > mat_count

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('EXTRA RTL OUTPUTS\n');
    fprintf('============================================================\n');

    for idx = mat_count+1 : rtl_count

        fprintf('RTL[%3d] = %d\n', idx-1, rtl_vals(idx));

    end

end

%% =====================================================
%% ERROR MAP
%% =====================================================

% if rtl_count >= 676
% 
%     rtl_map = reshape(rtl_vals(1:676),26,26);
% 
%     figure;
%     imagesc(abs(double(conv_ref) - double(rtl_map)));
%     axis image;
%     colorbar;
%     title('Absolute Error Map');
% 
% end