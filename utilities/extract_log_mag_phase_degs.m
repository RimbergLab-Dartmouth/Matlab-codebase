function [log_mag_data,phase_degs_data]=extract_log_mag_phase_degs(lin_mag_data,phase_radians_data)
    log_mag_data=20*log10(lin_mag_data);
    phase_degs_data=360.*phase_radians_data/2/pi;
end