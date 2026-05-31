%% 加窗 Sinc 插值与理想 Sinc 插值对比实验
% 功能：对比无窗（直接截断）与加窗（Kaiser窗）Sinc插值的效果差异
%       通过图像和一维波形剖面图解释加窗如何抑制 Gibbs 振铃

clear; clc; close all;

%% ==================== 步骤 0: 读取图像 ====================
img_original = imread('cameraman.tif');
if size(img_original,3) == 3
    img_original = rgb2gray(img_original);
end
img_original = double(img_original);

% 截取一小块区域以便清晰观察边缘振铃
img_small = img_original(1:64, 1:64);

figure('Name', 'Step 0: Initial Low-Resolution Image', 'NumberTitle', 'off');
imshow(img_small, []);
title('Initial Low-Resolution Image (64×64)', 'FontSize', 14);

%% ==================== 参数设置 ====================
scale = 3;      % 放大倍数
R = 5;          % Sinc 核半径（核尺寸 = 2R+1）
beta = 5;       % Kaiser 窗参数（beta越大旁瓣衰减越快，主瓣略宽）

%% ==================== Step 1: Up-sampling (Zero-Padding) ====================
[m, n] = size(img_small);
M = m * scale;
N = n * scale;
img_upsampled = zeros(M, N);
img_upsampled(1:scale:end, 1:scale:end) = img_small;

%% ==================== Step 2: 生成理想 Sinc 核（无窗） ====================
% 生成亚像素精度的一维核（匹配放大倍数）
x = -R:1/scale:R;
h_ideal_1d = sinc(x);

% 二维可分离核（直接截断 = 乘矩形窗）
h_ideal_2d = h_ideal_1d' * h_ideal_1d;
h_ideal_2d = h_ideal_2d / sum(h_ideal_2d(:));   % 归一化

%% ==================== Step 3: 生成加窗 Sinc 核（Kaiser窗） ====================
% 生成一维 Kaiser 窗
w_1d = kaiser(length(x), beta)';   % 注意转置为行向量
% 加窗：理想 Sinc 乘以 Kaiser 窗
h_win_1d = h_ideal_1d .* w_1d;

% 二维可分离加窗核
h_win_2d = h_win_1d' * h_win_1d;
h_win_2d = h_win_2d / sum(h_win_2d(:));   % 归一化

%% ==================== Step 4: 卷积重建（理想 Sinc） ====================
img_ideal_rows = conv2(img_upsampled, h_ideal_1d, 'same');
img_ideal = conv2(img_ideal_rows, h_ideal_1d', 'same');

%% ==================== Step 5: 卷积重建（加窗 Sinc） ====================
img_win_rows = conv2(img_upsampled, h_win_1d, 'same');
img_win = conv2(img_win_rows, h_win_1d', 'same');

%% ==================== 图像对比展示 ====================
figure('Name', 'Comparison of Sinc Interpolation Results: With vs. Without Windowing', 'NumberTitle', 'off');
subplot(1,3,1);
imshow(img_small, []); title('Original Low Resolution', 'FontSize', 12);
subplot(1,3,2);
imshow(img_ideal, []); title('ideal Sinc (No Window / Direct Truncation)', 'FontSize', 12);
subplot(1,3,3);
imshow(img_win, []); title('Windowed Sinc (Kaiser Window)', 'FontSize', 12);
impixelinfo;

% 局部放大对比（截取边缘区域）
figure('Name', 'details-rining', 'NumberTitle', 'off');
subplot(1,2,1);
imshow(img_ideal(60:140, 60:140), []); 
title('ideal Sinc：Pronounced ringing ripples', 'FontSize', 12);
subplot(1,2,2);
imshow(img_win(60:140, 60:140), []); 
title('Windowed Sinc: Significant Ringing Suppression', 'FontSize', 12);

%% ==================== 一维核波形对比 ====================
figure('Name', 'Comparison of 1D Interpolation Kernel Waveforms', 'NumberTitle', 'off');
plot(x, h_ideal_1d, 'b-', 'LineWidth', 1.5); hold on;
plot(x, h_win_1d, 'r-', 'LineWidth', 1.5);
plot(x, w_1d / max(w_1d) * max(h_ideal_1d), 'k--', 'LineWidth', 1); % 归一化显示窗形状
grid on;
xlabel('Distance (Pixels)'); ylabel('weight');
title('1D Sinc kernel：no wind vs.have wind (Kaiser)', 'FontSize', 14);
legend('ideal Sinc ', 'windowed Sinc', 'Kaiser', 'Location', 'best');
xlim([-R, R]);

%% ==================== 一维图像剖面波形对比 ====================
% 选取包含强边缘的一行（例如经过摄影师衣服边缘的行）
row_original = 40;          % 原始图像中的行
row_upsampled = row_original * scale;

% 提取三种情况的该行像素值
original_line = img_small(row_original, :);
ideal_line = img_ideal(row_upsampled, :);
win_line = img_win(row_upsampled, :);

% x 轴坐标
x_original = 1:length(original_line);
x_upsampled = linspace(1, length(original_line), length(ideal_line));

figure('Name', 'Windowing Suppresses Gibbs Overshoot', 'NumberTitle', 'off');

% 子图1：原始离散采样点
subplot(3,1,1);
stem(x_original, original_line, 'b', 'LineWidth', 1.2, 'MarkerSize', 5);
grid on; xlim([1, length(original_line)]);
ylabel('Grayscale'); title('Original Low-Resolution Sample Points', 'FontSize', 12);

% 子图2：理想 Sinc 重建波形（标注过冲）
subplot(3,1,2);
plot(x_upsampled, ideal_line, 'b-', 'LineWidth', 1.5); grid on; hold on;
stem(x_original, original_line, 'b', 'LineWidth', 1, 'MarkerSize', 4);
xlim([1, length(original_line)]);
ylabel('Grayscale'); title('ideal Sinc: have GIBBS', 'FontSize', 12);
% 用箭头标注过冲位置（以实际数据自动确定一个峰值点）
[~, idx] = max(ideal_line(30:end-30)); % 避开边界
idx = idx + 29;
text(x_upsampled(idx), ideal_line(idx)+10, '← 过冲', 'Color', 'red', 'FontSize', 10);

% 子图3：加窗 Sinc 重建波形
subplot(3,1,3);
plot(x_upsampled, win_line, 'r-', 'LineWidth', 1.5); grid on; hold on;
stem(x_original, original_line, 'b', 'LineWidth', 1, 'MarkerSize', 4);
xlim([1, length(original_line)]);
xlabel('Distance (Pixels)'); ylabel('Grayscale');
title('windowed Sinc (Kaiser):overshoot is significantly reduced.', 'FontSize', 12);

%% ==================== 定量分析：计算过冲幅度 ====================
% 寻找一个局部边缘区域计算过冲百分比（简化：取行向量中最大值与局部均值的差）
local_mean = mean(original_line(20:30)); % 边缘一侧的平均灰度
overshoot_ideal = (max(ideal_line(35:45)) - local_mean) / local_mean * 100;
overshoot_win = (max(win_line(35:45)) - local_mean) / local_mean * 100;

fprintf('\n========== 过冲幅度对比 ==========\n');
fprintf('理想 Sinc (无窗) 过冲幅度: %.1f%%\n', overshoot_ideal);
fprintf('加窗 Sinc (Kaiser) 过冲幅度: %.1f%%\n', overshoot_win);
fprintf('过冲抑制率: %.1f%%\n', (overshoot_ideal-overshoot_win)/overshoot_ideal*100);
fprintf('==================================\n');

%% ==================== 波形解释文字（输出到命令窗口） ====================
fprintf('\n========== 波形解释 ==========\n');
fprintf('1. 理想 Sinc 核直接截断等效于乘矩形窗，频域产生旁瓣泄漏 -> 时域 Gibbs 振铃。\n');
fprintf('2. Kaiser 窗使核两端平滑衰减至零，旁瓣大幅降低 -> 振铃抑制。\n');
fprintf('3. 从图像剖面图可见：加窗后边缘过冲幅度显著减小，曲线更平滑。\n');
fprintf('================================\n');