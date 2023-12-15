function [gamma_real,gamma_imag]=q_circle_with_freq_flucs(freq_points,gamma_int,gamma_ext,freq_res, sigma)
    % Bhar eq 3.7
    gamma = 1 - sqrt(pi/2).*gamma_ext./sigma.*fadf((1i*(gamma_int+gamma_ext) - 2*(freq_points - freq_res))./(2*sqrt(2).*sigma));
    gamma_real = real(gamma);
    gamma_imag = imag(gamma);
end