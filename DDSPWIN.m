%%windowed Sinc and ideal Sinc
clear; clc; close all;

%% read graph
img_original = imread('cameraman.tif');
if size(img_original,3) == 3
    img_original = rgb2gray(img_original);
end
img_original = double(img_original);

img_small = img_original(1:64, 1:64);

figure('Name', 'Step 0: Initial Low-Resolution Image', 'NumberTitle', 'off');
imshow(img_small, []);
title('Initial Low-Resolution Image (64×64)', 'FontSize', 14);

%% parameter
scale = 3;
R = 5;
beta = 5;

%% Up-sampling (Zero-Padding)
[m, n] = size(img_small);
M = m * scale;
N = n * scale;
img_upsampled = zeros(M, N);
img_upsampled(1:scale:end, 1:scale:end) = img_small;

%% ideal Sinc
x = -R:1/scale:R;
h_ideal_1d = sinc(x);

h_ideal_2d = h_ideal_1d' * h_ideal_1d;
h_ideal_2d = h_ideal_2d / sum(h_ideal_2d(:));

%% windowed Sinc（Kaiser)
w_1d = kaiser(length(x), beta)'; 
h_win_1d = h_ideal_1d .* w_1d;

h_win_2d = h_win_1d' * h_win_1d;
h_win_2d = h_win_2d / sum(h_win_2d(:));   % 归一化

%% ideal Sinc
img_ideal_rows = conv2(img_upsampled, h_ideal_1d, 'same');
img_ideal = conv2(img_ideal_rows, h_ideal_1d', 'same');

%% concolution windowed Sinc
img_win_rows = conv2(img_upsampled, h_win_1d, 'same');
img_win = conv2(img_win_rows, h_win_1d', 'same');

figure('Name', 'Comparison of Sinc Interpolation Results: With vs. Without Windowing', 'NumberTitle', 'off');
subplot(1,3,1);
imshow(img_small, []); title('Original Low Resolution', 'FontSize', 12);
subplot(1,3,2);
imshow(img_ideal, []); title('ideal Sinc (No Window / Direct Truncation)', 'FontSize', 12);
subplot(1,3,3);
imshow(img_win, []); title('Windowed Sinc (Kaiser Window)', 'FontSize', 12);
impixelinfo;

figure('Name', 'details-rining', 'NumberTitle', 'off');
subplot(1,2,1);
imshow(img_ideal(60:140, 60:140), []); 
title('ideal Sinc：Pronounced ringing ripples', 'FontSize', 12);
subplot(1,2,2);
imshow(img_win(60:140, 60:140), []); 
title('Windowed Sinc: Significant Ringing Suppression', 'FontSize', 12);

figure('Name', 'Comparison of 1D Interpolation Kernel Waveforms', 'NumberTitle', 'off');
plot(x, h_ideal_1d, 'b-', 'LineWidth', 1.5); hold on;
plot(x, h_win_1d, 'r-', 'LineWidth', 1.5);
plot(x, w_1d / max(w_1d) * max(h_ideal_1d), 'k--', 'LineWidth', 1);
grid on;
xlabel('Distance (Pixels)'); ylabel('weight');
title('1D Sinc kernel：no wind vs.have wind (Kaiser)', 'FontSize', 14);
legend('ideal Sinc ', 'windowed Sinc', 'Kaiser', 'Location', 'best');
xlim([-R, R]);

row_original = 40; 
row_upsampled = row_original * scale;

original_line = img_small(row_original, :);
ideal_line = img_ideal(row_upsampled, :);
win_line = img_win(row_upsampled, :);

%x
x_original = 1:length(original_line);
x_upsampled = linspace(1, length(original_line), length(ideal_line));

figure('Name', 'Windowing Suppresses Gibbs Overshoot', 'NumberTitle', 'off');

subplot(3,1,1);
stem(x_original, original_line, 'b', 'LineWidth', 1.2, 'MarkerSize', 5);
grid on; xlim([1, length(original_line)]);
ylabel('Grayscale'); title('Original Low-Resolution Sample Points', 'FontSize', 12);

subplot(3,1,2);
plot(x_upsampled, ideal_line, 'b-', 'LineWidth', 1.5); grid on; hold on;
stem(x_original, original_line, 'b', 'LineWidth', 1, 'MarkerSize', 4);
xlim([1, length(original_line)]);
ylabel('Grayscale'); title('ideal Sinc: have GIBBS', 'FontSize', 12);
[~, idx] = max(ideal_line(30:end-30));
idx = idx + 29;
text(x_upsampled(idx), ideal_line(idx)+10, '← 过冲', 'Color', 'red', 'FontSize', 10);

subplot(3,1,3);
plot(x_upsampled, win_line, 'r-', 'LineWidth', 1.5); grid on; hold on;
stem(x_original, original_line, 'b', 'LineWidth', 1, 'MarkerSize', 4);
xlim([1, length(original_line)]);
xlabel('Distance (Pixels)'); ylabel('Grayscale');
title('windowed Sinc (Kaiser):overshoot is significantly reduced.', 'FontSize', 12);

local_mean = mean(original_line(20:30));
overshoot_ideal = (max(ideal_line(35:45)) - local_mean) / local_mean * 100;
overshoot_win = (max(win_line(35:45)) - local_mean) / local_mean * 100;


