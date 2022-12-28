function [gamma_real,gamma_imag]=q_circle(freq_points,gamma_int,gamma_ext,freq_res)
%      gamma_real= ((freq_points-freq_res).^2+gamma_int^2-gamma_ext^2)./((freq_points-freq_res).^2+(gamma_int+gamma_ext)^2);
%      gamma_imag=2*(freq_points-freq_res)*gamma_ext./((freq_points-freq_res).^2+(gamma_int+gamma_ext)^2);
     gamma = ((freq_points - freq_res)-1i.*(gamma_int - gamma_ext)/2)./((freq_points - freq_res) - 1i*(gamma_int + gamma_ext)/2);
     gamma_real = real(gamma);
     gamma_imag = imag(gamma);
end