%FFT
X_original = fftshift(fft(x));
X_pad_time = fftshift(fft(x_pad_time));
f = (-N/2:N/2-1)/N;
f_pad = (-N_pad_time/2:N_pad_time/2-1)/N_pad_time;

subplot(3, 2, 2);
stem(f, abs(X_original), 'b.', 'MarkerSize', 10, 'DisplayName', 'initial specturm'); hold on;
plot(f_pad, abs(X_pad_time), 'r-', 'LineWidth', 1, 'DisplayName', 'after-sepcturm');
title('2. Time-domain zero padding);
xlabel('Normalize frequency'); ylabel('amplitude');
xlim([-0.5, 0.5]); legend; grid on;

%%Interpolation
X = fft(x);
N_interp = 256;
% 在 Nyquist 频率处（频谱中间）插入零
X_pad_freq = zeros(1, N_interp);
X_pad_freq(1:N/2) = X(1:N/2); 
X_pad_freq(N_interp-N/2+1:N_interp) = X(N/2+1:N); 
x_interp = real(ifft(X_pad_freq)) * (N_interp/N);
t_interp = (0:N_interp-1)/N_interp;

subplot(3, 2, 3);
stem(t, x, 'b.', 'MarkerSize', 15, 'DisplayName', 'initial sample points'); hold on;
plot(t_interp, x_interp, 'r-', 'LineWidth', 1.2, 'DisplayName', 'after-spectrum');
title('3. Frequency domain zero padding');
xlabel('normalize time'); ylabel('amplitude');
ylim([-0.2, 1.2]); legend; grid on;

%% Hamming Windowing
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
title('4. Haming');
xlabel('normalize time'); ylabel('amplitude');
ylim([-0.2, 1.2]); legend; grid on;

subplot(3, 2, 5);
plot(t, x_truncated, 'r-', 'LineWidth', 1.5, 'DisplayName', 'no window (overshoot~9%)'); hold on;
plot(t, x_win_truncated, 'g-', 'LineWidth', 1.5, 'DisplayName', 'after window (overshoot~1%)');
plot(t, x, 'k--', 'LineWidth', 1);
title('5. Adding windows to eliminate overshoot');
xlabel('normalize time'); ylabel('amplitude');
ylim([-0.2, 1.2]); legend; grid on;

%%Boundary Effect
kernel = [0.25, 0.5, 0.25]; 
x_conv = conv(x, kernel, 'same'); 

subplot(3, 2, 6);
plot(t, x, 'k--', 'LineWidth', 1.5, 'DisplayName', 'initial signal'); hold on;
plot(t, x_conv, 'm-', 'LineWidth', 1.5, 'DisplayName', 'after convolution');
area(t(1:3), x_conv(1:3), 'FaceColor', 'm', 'FaceAlpha', 0.2);
area(t(end-2:end), x_conv(end-2:end), 'FaceColor', 'm', 'FaceAlpha', 0.2);
title('6. boundary effect');
xlabel('normalize time'); ylabel('amplitude');
ylim([-0.2, 1.2]); legend; grid on;
