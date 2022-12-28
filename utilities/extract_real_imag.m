function [real_data,imag_data]=extract_real_imag(freq,lin_mag,phase_radians)   %lin_mag: bias points x number of points, phase: bias points x number of points
%     [freq,lin_mag,phase_radians]=extract_lin_mag_and_phase_radians(freq,log_mag,phase_degrees);
    real_data=lin_mag.*cos(phase_radians);
    imag_data=lin_mag.*sin(phase_radians);
end
