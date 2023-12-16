function [gamma_real,gamma_imag]=q_circle_with_freq_flucs_and_angle(freq_points,gamma_int,gamma_ext,freq_res, sigma, angle_degs)
% Bhar eq 3.7 + rotation
    angle_radians = 2*pi/360*angle_degs;
    gamma = 1 - sqrt(pi/2).*gamma_ext./sigma.*fadf((1i*(gamma_int+gamma_ext) - 2*(freq_points - freq_res))./(2*sqrt(2).*sigma));
    gamma = gamma - 1;
    
    gamma = gamma.*exp(-1i*angle_radians);
    % account for radius change ?
    % gamma = gamma.*exp(-1i*angle_radians).*cos(angle_radians);

    gamma = gamma +1;
    gamma_real = real(gamma);
    gamma_imag = imag(gamma);
end