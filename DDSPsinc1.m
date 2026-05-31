%% 理想 Sinc 插值完整演示（分步输出）
% 作者：DSP 课程实验
% 功能：展示 Up-sampling (Zero-Padding) → 理想 Sinc 低通滤波的完整流程

clear; clc; close all;

%% ==================== 步骤 0: 读取图像 ====================
% 使用 MATLAB 内置的 'cameraman.tif'（也可换成你的测试图）
img_original = imread('cameraman.tif');
if size(img_original,3) == 3
    img_original = rgb2gray(img_original);
end
img_original = double(img_original);

%% ==================== 参数设置 ====================
scale = 3;                  % 放大倍数
R = 5;                      % Sinc 核半径（核尺寸 = 2R+1）
% 注意：R 越大越接近理想 Sinc，但计算量增加，这里 R=5 已能体现效果

%% ==================== 步骤 1: Up-sampling (Zero-Padding) ====================
[m, n] = size(img_original);
M = m * scale;
N = n * scale;

% 初始化上采样图像（全零矩阵）
img_upsampled = zeros(M, N);
% 将原始像素放入对应位置（步长为 scale）
img_upsampled(1:scale:end, 1:scale:end) = img_original;

figure('Name', 'Step 1: Up-sampling (Zero-Padding) result', 'NumberTitle', 'off');
imshow(img_upsampled, []);
title(sprintf('up-sampling (Zero-Padding) - size: %d×%d', M, N), 'FontSize', 14);
impixelinfo;

% 可视化上采样后的局部放大（展示零值网格）
figure('Name', 'Zero-Padding detail', 'NumberTitle', 'off');
% 显示左上角一小块区域（例如 30×30）
imshow(img_upsampled(1:30, 1:30), [], 'InitialMagnification', 800);
title('Up-sampling: Black represents zero values, while bright spots represent original pixels.', 'FontSize', 14);

%% ==================== 步骤 2: 构建理想二维 Sinc 插值核 ====================
% 生成一维 Sinc 核
x = -R:1/scale:R;          % 以亚像素精度采样（匹配放大倍数）
h_1d = sinc(x);

% 利用可分离性构建二维核
h_2d = h_1d' * h_1d;

% 归一化（确保卷积后亮度不变）
h_2d = h_2d / sum(h_2d(:));

% 可视化二维 Sinc 核
figure('Name', 'Step 2: ideal 2D Sinc Interpolation Kernel', 'NumberTitle', 'off');
surf(x, x, h_2d, 'EdgeColor', 'none');
colormap('jet'); colorbar;
xlabel('x'); ylabel('y'); zlabel('h(x,y)');
title(sprintf('2D Sinc Kernel (radius R=%d, kernel size %d×%d)', R, size(h_2d,1), size(h_2d,2)), 'FontSize', 14);
view(45, 30);

% 一维剖面图（用于波形解释）
figure('Name', '1D Sinc Kernel waveform', 'NumberTitle', 'off');
plot(x, h_1d, 'b-', 'LineWidth', 2); grid on;
xlabel('distance (pixel)'); ylabel('weight');
title('1D Sinc Interpolation Kernel h(x) = sinc(x)', 'FontSize', 14);
hold on;
% 标注原点
plot(0, 1, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
text(0.2, 0.9, 'h(0)=1', 'Color', 'r', 'FontSize', 12);
% 标注过零点
for k = [-3, -2, -1, 1, 2, 3]
    plot(k, 0, 'ko', 'MarkerSize', 6);
end
legend('sinc(x)', 'center', 'Zero Crossing');

%% ==================== 步骤 3: 低通滤波（卷积） ====================
% 利用可分离性加速卷积：先对行卷积，再对列卷积
% 注意：这里使用 'same' 保证输出尺寸与上采样图像一致
img_filtered_rows = conv2(img_upsampled, h_1d, 'same');
img_result = conv2(img_filtered_rows, h_1d', 'same');

figure('Name', 'Step 3: Ideal Sinc Interpolation result', 'NumberTitle', 'off');
imshow(img_result, []);
title(sprintf('Ideal Sinc Interpolation Reconstruction Results (size: %d×%d)', M, N), 'FontSize', 14);
impixelinfo;

%% ==================== 步骤 4: 对比与波形解释 ====================
% 选取图像中的一行（例如第 32 行）进行一维波形对比
row_original = 32;                     % 原始图像中的行
row_upsampled = row_original * scale;  % 对应上采样图像中的行

% 提取原始图像和重建图像的该行像素值
original_line = img_original(row_original, :);
upsampled_line = img_upsampled(row_upsampled, :);
reconstructed_line = img_result(row_upsampled, :);

% 创建 x 轴坐标
x_original = 1:length(original_line);
x_upsampled = linspace(1, length(original_line), length(upsampled_line));

figure('Name', '1D Waveform Comparison：Visualization of Interpolation Principles', 'NumberTitle', 'off');
% 子图1：原始离散采样点
subplot(3,1,1);
stem(x_original, original_line, 'b', 'LineWidth', 1.5, 'MarkerSize', 6);
grid on;
xlabel('pixel position'); ylabel('Grayscale value');
title('Original Low-Resolution Sample Points (discrete)', 'FontSize', 12);
xlim([1, length(original_line)]);

% 子图2：上采样（插零）后的波形
subplot(3,1,2);
stem(x_upsampled, upsampled_line, 'r', 'LineWidth', 0.5, 'MarkerSize', 3);
grid on;
xlabel('pixel position'); ylabel('Grayscale value');
title('After Zero-Padding', 'FontSize', 12);
xlim([1, length(original_line)]);

% 子图3：Sinc 插值重建后的连续波形
subplot(3,1,3);
plot(x_upsampled, reconstructed_line, 'g-', 'LineWidth', 2); grid on;
hold on;
% 叠加原始采样点
stem(x_original, original_line, 'b', 'LineWidth', 1, 'MarkerSize', 5);
xlabel('pixel position'); ylabel('Gray value');
title('after Sinc interpolation reconstruction', 'FontSize', 12);
xlim([1, length(original_line)]);
legend('reconstruction curve', 'initial sample');

%% ==================== 额外：对比不同插值方法 ====================
% 使用 MATLAB 内置函数作为参照
img_nearest = imresize(img_original, scale, 'nearest');
img_bilinear = imresize(img_original, scale, 'bilinear');
img_bicubic = imresize(img_original, scale, 'bicubic');

figure('Name', 'Comparison of Different Interpolation Methods', 'NumberTitle', 'off');
subplot(2,3,1); imshow(img_original, []); title('Original Low Resolution');
subplot(2,3,2); imshow(img_upsampled, []); title('Zero-Padding');
subplot(2,3,3); imshow(img_result, []); title('Ideal Sinc (Direct Truncation)');
subplot(2,3,4); imshow(img_bilinear, []); title('Bilinear Interpolation');
subplot(2,3,5); imshow(img_bicubic, []); title('Bicubic Interpolation');

%% ==================== 波形解释文字（输出到命令窗口） ====================
fprintf('\n========== 波形解释 ==========\n');
fprintf('1. 第一张图：原始离散采样点，只有 64 个像素值。\n');
fprintf('2. 第二张图：Zero-Padding 后，像素间插入零值，产生高频镜像。\n');
fprintf('3. 第三张图：通过 Sinc 低通滤波，零值被"填充"为平滑过渡值，\n');
fprintf('   重建曲线严格穿过原始采样点（因为 sinc(0)=1, sinc(n)=0）。\n');
fprintf('================================\n');