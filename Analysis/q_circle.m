function [gamma_real,gamma_imag]=q_circle(freq_points,gamma_int,gamma_ext,freq_res)
    % Bhar eq 2.31
    gamma = ((freq_points - freq_res)-1i.*(gamma_int - gamma_ext)/2)./((freq_points - freq_res) - 1i*(gamma_int + gamma_ext)/2);
    gamma_real = real(gamma);
    gamma_imag = imag(gamma);
end