function [lin_mag_data,phase_radians_data]=extract_lin_mag_and_phase_radians(freq,log_mag_data,phase_data)
         lin_mag_data=10.^(log_mag_data/20); 
         phase_radians_data=2*pi/360.*phase_data;
end