function [lin_mag_data,phase_radians_data]=extract_lin_mag_phase_from_real_imag(real_data,imag_data,freq_data)
     lin_mag_data=sqrt(real_data.^2+imag_data.^2);
     phase_radians_data=atan2(imag_data,real_data);
end
