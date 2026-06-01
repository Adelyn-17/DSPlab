clear; clc; close all;

img_ref = imread('cameraman.tif');
if size(img_ref,3) == 3
    img_ref = rgb2gray(img_ref);
end
img_ref = double(img_ref);

[M_ref, N_ref] = size(img_ref);

%%Low-Resolution Input
scale = 3;
% Downsample by integer factor (using bicubic to avoid aliasing artifacts)
img_lr = imresize(img_ref, 1/scale, 'bicubic');

[m_lr, n_lr] = size(img_lr);

%%Parameters
R = 5;
a_values = 2:0.5:4;
% a_values = [2, 3, 4];

%% Lanczos 1D kernel Interpolation Functions
lanczos_1d = @(x, a) sinc(x) .* sinc(x/a) .* (abs(x) < a);

function img_out = interpolate_separable(img_up, scale, R, kernel_1d_func)
    [M, N] = size(img_up);
    x = -R : 1/scale : R;
    h_1d = kernel_1d_func(x);
    h_1d = h_1d / sum(h_1d);
    img_rows = conv2(img_up, h_1d, 'same');
    img_out = conv2(img_rows, h_1d', 'same');
end

%% ==================== Step 4: Zero-Padding for All Methods ====================
img_up = zeros(m_lr*scale, n_lr*scale);
img_up(1:scale:end, 1:scale:end) = img_lr;

psnr_lanczos = zeros(1, length(a_values));
ssim_lanczos = zeros(1, length(a_values));

fprintf('Evaluating Lanczos with different a values...\n');
for idx = 1:length(a_values)
    a = a_values(idx);
    kernel_func = @(x) lanczos_1d(x, a);
    img_lanczos = interpolate_separable(img_up, scale, R, kernel_func);
    
    img_crop = img_lanczos(1:M_ref, 1:N_ref);

    psnr_lanczos(idx) = psnr(img_crop, img_ref, 255);
    ssim_lanczos(idx) = ssim(img_crop, img_ref);
    
    fprintf('  a = %.1f : PSNR = %.2f dB, SSIM = %.4f\n', a, psnr_lanczos(idx), ssim_lanczos(idx));
end

%% SSIM
[~, opt_idx] = max(ssim_lanczos);
a_opt = a_values(opt_idx);
fprintf('\nOptimal a based on SSIM: a = %.1f\n', a_opt);

%% Linear and Bicubic
img_linear = imresize(img_lr, scale, 'bilinear');
img_bicubic = imresize(img_lr, scale, 'bicubic');

kernel_opt = @(x) lanczos_1d(x, a_opt);
img_lanczos_opt = interpolate_separable(img_up, scale, R, kernel_opt);

img_linear_crop = img_linear(1:M_ref, 1:N_ref);
img_bicubic_crop = img_bicubic(1:M_ref, 1:N_ref);
img_lanczos_crop = img_lanczos_opt(1:M_ref, 1:N_ref);

psnr_linear = psnr(img_linear_crop, img_ref, 255);
ssim_linear = ssim(img_linear_crop, img_ref);
psnr_bicubic = psnr(img_bicubic_crop, img_ref, 255);
ssim_bicubic = ssim(img_bicubic_crop, img_ref);
psnr_lanc_opt = psnr_lanczos(opt_idx);
ssim_lanc_opt = ssim_lanczos(opt_idx);

fprintf('\n========== Final Comparison ==========\n');
fprintf('Method           PSNR (dB)   SSIM\n');
fprintf('------------------------------------\n');
fprintf('Linear           %8.2f   %.4f\n', psnr_linear, ssim_linear);
fprintf('Bicubic          %8.2f   %.4f\n', psnr_bicubic, ssim_bicubic);
fprintf('Lanczos (a=%.1f)  %8.2f   %.4f\n', a_opt, psnr_lanc_opt, ssim_lanc_opt);
fprintf('=====================================\n');

% Figure 1: Lanczos 'a' sweep
figure('Name', 'Lanczos Parameter Sweep', 'NumberTitle', 'off');
yyaxis left;
plot(a_values, psnr_lanczos, 'b-o', 'LineWidth', 2);
ylabel('PSNR (dB)');
yyaxis right;
plot(a_values, ssim_lanczos, 'r-s', 'LineWidth', 2);
ylabel('SSIM');
xlabel('Lanczos a parameter');
grid on;
title('Effect of Lanczos a on PSNR and SSIM');
legend('PSNR', 'SSIM', 'Location', 'best');

% Figure 2: Bar chart comparing methods
figure('Name', 'Interpolation Methods Comparison', 'NumberTitle', 'off');
methods = {'Linear', 'Bicubic', sprintf('Lanczos (a=%.1f)', a_opt)};
psnr_vals = [psnr_linear, psnr_bicubic, psnr_lanc_opt];
ssim_vals = [ssim_linear, ssim_bicubic, ssim_lanc_opt];

subplot(1,2,1);
bar(psnr_vals);
set(gca, 'XTickLabel', methods, 'XTickLabelRotation', 15);
ylabel('PSNR (dB)');
title('PSNR Comparison');
grid on;

subplot(1,2,2);
bar(ssim_vals);
set(gca, 'XTickLabel', methods, 'XTickLabelRotation', 15);
ylabel('SSIM');
title('SSIM Comparison');
grid on;

figure('Name', 'Visual Quality Comparison', 'NumberTitle', 'off');
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile; imshow(img_ref, []); title('Ground Truth (Reference)');
nexttile; imshow(img_linear_crop, []); 
title(sprintf('Linear (PSNR=%.2f, SSIM=%.4f)', psnr_linear, ssim_linear));
nexttile; imshow(img_bicubic_crop, []); 
title(sprintf('Bicubic (PSNR=%.2f, SSIM=%.4f)', psnr_bicubic, ssim_bicubic));
nexttile; imshow(img_lanczos_crop, []); 
title(sprintf('Lanczos a=%.1f (PSNR=%.2f, SSIM=%.4f)', a_opt, psnr_lanc_opt, ssim_lanc_opt));

roi_row = 120:160;
roi_col = 100:140;
figure('Name', 'Zoomed Detail Comparison', 'NumberTitle', 'off');
tiledlayout(2, 2, 'TileSpacing', 'tight', 'Padding', 'tight');
nexttile; imshow(img_ref(roi_row, roi_col), []); title('Ground Truth');
nexttile; imshow(img_linear_crop(roi_row, roi_col), []); title('Linear');
nexttile; imshow(img_bicubic_crop(roi_row, roi_col), []); title('Bicubic');
nexttile; imshow(img_lanczos_crop(roi_row, roi_col), []); title(sprintf('Lanczos a=%.1f', a_opt));

% Save workspace for later use in report
save('interpolation_comparison.mat', 'a_values', 'psnr_lanczos', 'ssim_lanczos', ...
    'a_opt', 'psnr_linear', 'ssim_linear', 'psnr_bicubic', 'ssim_bicubic', ...
    'psnr_lanc_opt', 'ssim_lanc_opt');

fprintf('\nWorkspace saved to interpolation_comparison.mat\n');
