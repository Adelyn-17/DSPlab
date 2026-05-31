%% Adaptive Lanczos Interpolation based on Sobel Edge Detection
% Smooth regions use a=3 (wider support, accurate low-pass)
% Edge regions use a=2 (narrow support, reduced ringing)

clear; clc; close all;

%% ==================== 1. Prepare Images ====================
img_ref = im2double(imread('cameraman.tif'));
if size(img_ref, 3) == 3, img_ref = rgb2gray(img_ref); end
[M_ref, N_ref] = size(img_ref);

scale = 3; 
% Generate Low-Resolution image
img_lr = imresize(img_ref, 1/scale, 'bicubic');
[m_lr, n_lr] = size(img_lr);

%% ==================== 2. Sobel Edge Detection (The Detector) ====================
% Apply Sobel operator to the LR image to find gradients
[Gmag, ~] = imgradient(img_lr, 'sobel');

% Normalize gradient to [0, 1]
Gmag_norm = Gmag / max(Gmag(:));

% Create a "Soft Mask" (Weight matrix W)
% W approaches 1 at edges, and 0 in smooth regions.
% We multiply by a factor (e.g., 2.5) and clip to 1 to make edges more pronounced.
W_lr = min(Gmag_norm * 2.5, 1);

% Upsample the weight mask to HR size (using bilinear for smooth transitions)
W_hr = imresize(W_lr, scale, 'bilinear');
W_hr = W_hr(1:M_ref, 1:N_ref); % Ensure size match

%% ==================== 3. Interpolation Functions ====================
R = 5;
lanczos_1d = @(x, a) sinc(x) .* sinc(x/a) .* (abs(x) < a);

function img_out = interpolate_separable(img_up, scale, R, kernel_1d_func)
    x = -R : 1/scale : R;
    h_1d = kernel_1d_func(x);
    h_1d = (h_1d / sum(h_1d)) * scale; % DC Gain Compensation!
    img_rows = conv2(img_up, h_1d, 'same');
    img_out = conv2(img_rows, h_1d', 'same');
end

% Zero-pad the input
img_up = zeros(m_lr*scale, n_lr*scale);
img_up(1:scale:end, 1:scale:end) = img_lr;

%% ==================== 4. Generate Base Images ====================
% Generate a=2 image (Good for edges, less ringing)
kernel_a2 = @(x) lanczos_1d(x, 2);
img_a2 = interpolate_separable(img_up, scale, R, kernel_a2);
img_a2 = max(min(img_a2(1:M_ref, 1:N_ref), 1), 0);

% Generate a=3 image (Good for smooth areas, high sharpness)
kernel_a3 = @(x) lanczos_1d(x, 3);
img_a3 = interpolate_separable(img_up, scale, R, kernel_a3);
img_a3 = max(min(img_a3(1:M_ref, 1:N_ref), 1), 0);

%% ==================== 5. Adaptive Fusion ====================
% Equation: Output = Edge * (a=2) + Smooth * (a=3)
img_adaptive = W_hr .* img_a2 + (1 - W_hr) .* img_a3;

%% ==================== 6. Quantitative Metrics ====================
psnr_a2 = psnr(img_a2, img_ref);
ssim_a2 = ssim(img_a2, img_ref);

psnr_a3 = psnr(img_a3, img_ref);
ssim_a3 = ssim(img_a3, img_ref);

psnr_ad = psnr(img_adaptive, img_ref);
ssim_ad = ssim(img_adaptive, img_ref);

fprintf('========== Performance Comparison ==========\n');
fprintf('Lanczos (a=2)   : PSNR = %.2f dB, SSIM = %.4f\n', psnr_a2, ssim_a2);
fprintf('Lanczos (a=3)   : PSNR = %.2f dB, SSIM = %.4f\n', psnr_a3, ssim_a3);
fprintf('Adaptive Lanczos: PSNR = %.2f dB, SSIM = %.4f\n', psnr_ad, ssim_ad);
fprintf('============================================\n');

%% ==================== 7. Visualization ====================
figure('Name', 'Adaptive Lanczos Framework', 'Position', [100, 100, 1200, 400]);

% 1. Show the Edge Mask
subplot(1,3,1);
imshow(W_hr, []); colormap(gca, 'parula'); colorbar;
title('Upsampled Sobel Edge Mask (Weight W)');

% 2. Zoomed comparison ROI
roi_r = 120:170; roi_c = 100:150; % Tripod area

subplot(1,3,2);
imshow(img_a3(roi_r, roi_c), []);
title(sprintf('Standard Lanczos a=3\n(More ringing at edges)'));

subplot(1,3,3);
imshow(img_adaptive(roi_r, roi_c), []);
title(sprintf('Adaptive Lanczos\n(Ringing suppressed at edges)'));