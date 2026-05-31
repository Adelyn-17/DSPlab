clear; clc; close all;

N = 64;
t = (0:N-1)/N;

x = zeros(1, N);
x(1:N/2) = 1;

figure('Position', [100, 100, 1200, 800]);

X = fft(x);
M = 16;
X_truncated = zeros(1, N);
X_truncated(1:M) = X(1:M);
X_truncated(N-M+2:N) = X(N-M+2:N);
x_truncated = real(ifft(X_truncated));

subplot(3, 2, 1);
plot(t, x, 'k--', 'LineWidth', 1.5, 'DisplayName', 'initial wave'); hold on;
plot(t, x_truncated, 'r-', 'LineWidth', 1.2, 'DisplayName', 'overshoot');
title('1.  Overshoot');
xlabel('time'); ylabel('amplitude');
ylim([-0.2, 1.2]); legend; grid on;

%% Zero Padding in Time Domain
N_pad_time = 256;
x_pad_time = [x, zeros(1, N_pad_time - N)];
t_pad_time = (0:N_pad_time-1)/N_pad_time;

%FFT
X_original = fftshift(fft(x));
X_pad_time = fftshift(fft(x_pad_time));
f = (-N/2:N/2-1)/N;
f_pad = (-N_pad_time/2:N_pad_time/2-1)/N_pad_time;

subplot(3, 2, 2);
stem(f, abs(X_original), 'b.', 'MarkerSize', 10, 'DisplayName', 'initialsepecturm'); hold on;
plot(f_pad, abs(X_pad_time), 'r-', 'LineWidth', 1, 'DisplayName', 'azp specturm');
title('2. interpolation');
xlabel('frequency'); ylabel('amplitude');
xlim([-0.5, 0.5]); legend; grid on;

%% Interpolation
X = fft(x);
N_interp = 256;
X_pad_freq = zeros(1, N_interp);
X_pad_freq(1:N/2) = X(1:N/2);
X_pad_freq(N_interp-N/2+1:N_interp) = X(N/2+1:N);
x_interp = real(ifft(X_pad_freq)) * (N_interp/N);
t_interp = (0:N_interp-1)/N_interp;

subplot(3, 2, 3);
stem(t, x, 'b.', 'MarkerSize', 15, 'DisplayName', 'sampling'); hold on;
plot(t_interp, x_interp, 'r-', 'LineWidth', 1.2, 'DisplayName', 'Spectrum zero-padding');
title('3. Spectrum zero-padding');
xlabel('time'); ylabel('amplitude');
ylim([-0.2, 1.2]); legend; grid on;

%% Windowing
% Hamming window
w = hamming(N)';
x_windowed = x .* w;

X_win = fft(x_windowed);
X_win_truncated = zeros(1, N);
X_win_truncated(1:M) = X_win(1:M);
X_win_truncated(N-M+2:N) = X_win(N-M+2:N);
x_win_truncated = real(ifft(X_win_truncated));

subplot(3, 2, 4);
plot(t, x, 'k--', 'LineWidth', 1.5, 'DisplayName', 'initial square wave'); hold on;
plot(t, x_windowed, 'b-', 'LineWidth', 1.2, 'DisplayName', 'after windowing');
title('4. hamming');
xlabel('time'); ylabel('amplitude');
ylim([-0.2, 1.2]); legend; grid on;

%% have/no window
subplot(3, 2, 5);
plot(t, x_truncated, 'r-', 'LineWidth', 1.5, 'DisplayName', 'no window (overshoot~9%)'); hold on;
plot(t, x_win_truncated, 'g-', 'LineWidth', 1.5, 'DisplayName', 'after window (overshoot~1%)');
plot(t, x, 'k--', 'LineWidth', 1);
title('5.Adding windows to eliminate overshoot');
xlabel('time'); ylabel('amplitude');
ylim([-0.2, 1.2]); legend; grid on;

%% Boundary Effect
kernel = [0.25, 0.5, 0.25]; 
x_conv = conv(x, kernel, 'same');

subplot(3, 2, 6);
plot(t, x, 'k--', 'LineWidth', 1.5, 'DisplayName', 'initial signal'); hold on;
plot(t, x_conv, 'm-', 'LineWidth', 1.5, 'DisplayName', 'after conolution');
area(t(1:3), x_conv(1:3), 'FaceColor', 'm', 'FaceAlpha', 0.2);
area(t(end-2:end), x_conv(end-2:end), 'FaceColor', 'm', 'FaceAlpha', 0.2);
title('6. 边界效应：边缘区域失真');
xlabel('归一化时间'); ylabel('幅度');
ylim([-0.2, 1.2]); legend; grid on;

%% 调整布局
sgtitle('数字信号处理核心概念演示：过冲、补零、加窗、边界效应', 'FontSize', 14, 'FontWeight', 'bold');
