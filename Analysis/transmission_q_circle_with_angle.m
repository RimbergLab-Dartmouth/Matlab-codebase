function [gamma_real,gamma_imag]=transmission_q_circle_with_angle(freq_points,kappa_int,kappa_ext,freq_res, angle_degs)
    %%% this code assumes that the damping rates (kappa_int, kappa_ext) are
    %%% real. Then uses eq. 12 of Khalil 2012 JAP to simulate impedance
    %%% mismatch. gamma is the reflection coefficient
     
    if imag(kappa_int) ~= 0
        disp('this function needs kappa_int to be real')
        return
    end
    if imag(kappa_ext) ~= 0 
        disp(['this functino needs kappa_ext to be real. complex part of the' ...
        'external damping rate needs to go in to the angle parameter'])
        return
    end
    
    angle_radians = 2*pi/360*angle_degs;
    q_int = freq_res/kappa_int;
    q_ext = freq_res/kappa_ext;
    q_tot = (1/q_int + cosd(angle_degs)^2/ q_ext)^(-1);  
    %%% the above is in order for the form below (eq. 12 in Khalil), to
    %%% correspond to the form q_ext in eq. (11) of Khalil - (see eq. 10)
    gamma = 1 - (q_tot/q_ext/secd(angle_degs))*exp(-1i*angle_radians)./(1 + 2*1i*q_tot/freq_res .* (freq_points - freq_res));     
    %      gamma = 1 - (q_tot/q_ext)./(1 + 2*1i*q_tot/freq_res .* (freq_points - freq_res));
    %      gamma = gamma - 1;
    %      gamma = gamma.*exp(-1i*angle_radians);
    %      gamma = gamma +1;
    gamma_real = real(gamma);
    gamma_imag = imag(gamma);
    %      gamma_real= ((freq_points-freq_res).^2+kappa_int^2-kappa_ext^2)./((freq_points-freq_res).^2+(kappa_int+kappa_ext)^2);
    %      gamma_imag=2*(freq_points-freq_res)*kappa_ext./((freq_points-freq_res).^2+(kappa_int+kappa_ext)^2);
end