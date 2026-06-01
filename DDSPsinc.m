clear; clc; close all;

%%Reading images
img_original = imread('cameraman.tif');
if size(img_original,3) == 3
    img_original = rgb2gray(img_original);
end
img_original = double(img_original);

img_small = img_original(1:64, 1:64);

figure('Name', 'Step 0: Original Low-Resolution Image', 'NumberTitle', 'off');
imshow(img_small, []);
title('Original Low-Resolution Image (64×64)', 'FontSize', 14);
impixelinfo;

%%Parameter settings
scale = 3;
R = 5;

%%Up-sampling (Zero-Padding)
[m, n] = size(img_small);
M = m * scale;
N = n * scale;

% upsampling(Parameter settings)
img_upsampled = zeros(M, N);
img_upsampled(1:scale:end, 1:scale:end) = img_small;

figure('Name', 'Step 1: Up-sampling (Zero-Padding) result', 'NumberTitle', 'off');
imshow(img_upsampled, []);
title(sprintf('up-sampling (Zero-Padding) - size: %d×%d', M, N), 'FontSize', 14);
impixelinfo;

% Local magnification
figure('Name', 'Zero-Padding detail', 'NumberTitle', 'off');
imshow(img_upsampled(1:30, 1:30), [], 'InitialMagnification', 800);
title('Up-sampling: Black represents zero values, while bright spots represent original pixels.', 'FontSize', 14);

x = -R:1/scale:R;
h_1d = sinc(x);

h_2d = h_1d' * h_1d;

h_2d = h_2d / sum(h_2d(:));

%Visualizing the 2D Sinc kernel
figure('Name', 'Step 2: ideal 2D Sinc Interpolation Kernel', 'NumberTitle', 'off');
surf(x, x, h_2d, 'EdgeColor', 'none');
colormap('jet'); colorbar;
xlabel('x'); ylabel('y'); zlabel('h(x,y)');
title(sprintf('2D Sinc Kernel (radius R=%d, kernel size %d×%d)', R, size(h_2d,1), size(h_2d,2)), 'FontSize', 14);
view(45, 30);

% 1-dimensional cross-section
figure('Name', '1D Sinc Kernel waveform', 'NumberTitle', 'off');
plot(x, h_1d, 'b-', 'LineWidth', 2); grid on;
xlabel('distance (pixel)'); ylabel('weight');
title('1D Sinc Interpolation Kernel h(x) = sinc(x)', 'FontSize', 14);
hold on;
plot(0, 1, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
text(0.2, 0.9, 'h(0)=1', 'Color', 'r', 'FontSize', 12);
for k = [-3, -2, -1, 1, 2, 3]
    plot(k, 0, 'ko', 'MarkerSize', 6);
end
legend('sinc(x)', 'center', 'Zero Crossing');

%%LPF(convolution)
img_filtered_rows = conv2(img_upsampled, h_1d, 'same');
img_result = conv2(img_filtered_rows, h_1d', 'same');

figure('Name', 'Step 3: Ideal Sinc Interpolation result', 'NumberTitle', 'off');
imshow(img_result, []);
title(sprintf('Ideal Sinc Interpolation Reconstruction Results (size: %d×%d)', M, N), 'FontSize', 14);
impixelinfo;

row_original = 32;
row_upsampled = row_original * scale;

original_line = img_small(row_original, :);
upsampled_line = img_upsampled(row_upsampled, :);
reconstructed_line = img_result(row_upsampled, :);

x_original = 1:length(original_line);
x_upsampled = linspace(1, length(original_line), length(upsampled_line));

figure('Name', '1D Waveform Comparison：Visualization of Interpolation Principles', 'NumberTitle', 'off');
% Original discrete sampling points
subplot(3,1,1);
stem(x_original, original_line, 'b', 'LineWidth', 1.5, 'MarkerSize', 6);
grid on;
xlabel('pixel position'); ylabel('Grayscale value');
title('Original Low-Resolution Sample Points (discrete)', 'FontSize', 12);
xlim([1, length(original_line)]);

% Upsampling (zero insertion)
subplot(3,1,2);
stem(x_upsampled, upsampled_line, 'r', 'LineWidth', 0.5, 'MarkerSize', 3);
grid on;
xlabel('pixel position'); ylabel('Grayscale value');
title('After Zero-Padding', 'FontSize', 12);
xlim([1, length(original_line)]);

% sinc interpolation
subplot(3,1,3);
plot(x_upsampled, reconstructed_line, 'g-', 'LineWidth', 2); grid on;
hold on;
stem(x_original, original_line, 'b', 'LineWidth', 1, 'MarkerSize', 5);
xlabel('pixel position'); ylabel('Gray value');
title('after Sinc interpolation reconstruction', 'FontSize', 12);
xlim([1, length(original_line)]);
legend('reconstruction curve', 'initial sample');

img_nearest = imresize(img_small, scale, 'nearest');
img_bilinear = imresize(img_small, scale, 'bilinear');
img_bicubic = imresize(img_small, scale, 'bicubic');

figure('Name', 'Comparison of Different Interpolation Methods', 'NumberTitle', 'off');
subplot(2,3,1); imshow(img_small, []); title('Original Low Resolution');
subplot(2,3,2); imshow(img_upsampled, []); title('Zero-Padding');
subplot(2,3,3); imshow(img_result, []); title('Ideal Sinc (Direct Truncation)');
subplot(2,3,4); imshow(img_bilinear, []); title('Bilinear Interpolation');
subplot(2,3,5); imshow(img_bicubic, []); title('Bicubic Interpolation');

fprintf('\n==========Waveform Explanation==========\n');
fprintf('1. The original discrete sampling points have only 64 pixel values.\n');
fprintf('2. after Zero-Padding\n');
fprintf('3. Sinc LPF\n');
fprintf('   The reconstructed curve passes precisely through the original sampling point.（因为 sinc(0)=1, sinc(n)=0）。\n');
fprintf('================================\n');
