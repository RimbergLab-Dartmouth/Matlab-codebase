ng_value = 0;
flux_value = 0;
res_freq_GHz = 5.786;
input_power_at_sample_dBm = -134;
kappa_int_MHz = 1.238;
kappa_ext_MHz = .8873;
kerr_MHz = find_kerr_MHz_ng_flux(ng_value, flux_value);

[theory_real, theory_imag, theory_log_mag, theory_phase, theory_probability_array, ...
theory_real_state_2, theory_imag_state_2, theory_log_mag_state_2, theory_phase_state_2, probability_array_state_2, ...
theory_real_state_3, theory_imag_state_3, theory_log_mag_state_3, theory_phase_state_3, probability_array_state_3, theory_probability, goodness_fit]= ...
fit_bifurcated_s11_kerr_flucs_for_single_detuning_power(data_real_with_flucs, data_imag_with_flucs, res_freq_GHz, xdata_1_before_m65/1e9, input_power_at_sample_dBm, kappa_int_MHz, kappa_ext_MHz, kerr_MHz);
figure
subplot(1,3,1)
plot(data_real_with_flucs, data_imag_with_flucs, 'b.')
hold on
plot(data_real_with_flucs(101:end), data_imag_with_flucs(101:end),'b*')
plot(theory_real, theory_imag, 'ro')
plot(theory_real_state_2, theory_imag_state_2, 'gv')
plot(theory_real_state_3, theory_imag_state_3, 'yx')

[lin_mag_data,phase_radians_data]=extract_lin_mag_phase_from_real_imag(data_real_with_flucs,data_imag_with_flucs,xdata_1_before_m65);
[log_mag_data, phase_degs_data] = extract_log_mag_phase_degs(lin_mag_data, phase_radians_data);

subplot(1,3,2)
plot((xdata_1_before_m65 - res_freq_GHz*1e9) /1e6, log_mag_data, 'b.')
hold on
plot((xdata_1_before_m65 - res_freq_GHz*1e9) /1e6, theory_log_mag, 'ro')
plot((xdata_1_before_m65 - res_freq_GHz*1e9) /1e6, theory_log_mag_state_2, 'gv')
plot((xdata_1_before_m65 - res_freq_GHz*1e9) /1e6, theory_log_mag_state_3, 'yx')

subplot(1,3,3)
plot((xdata_1_before_m65 - res_freq_GHz*1e9) /1e6, phase_degs_data, 'b.')
hold on
plot((xdata_1_before_m65 - res_freq_GHz*1e9) /1e6, theory_phase, 'ro')
plot((xdata_1_before_m65 - res_freq_GHz*1e9) /1e6, theory_phase_state_2, 'gv')
plot((xdata_1_before_m65 - res_freq_GHz*1e9) /1e6, theory_phase_state_3, 'yx')
sgtitle(['res freq = ' num2str(res_freq_GHz) 'GHz, input power at sample = ' num2str(input_power_at_sample_dBm) 'dBm'])

figure
plot((xdata_1_before_m65 - res_freq_GHz*1e9) /1e6, theory_probability)
hold on
plot((xdata_1_before_m65 - res_freq_GHz*1e9) /1e6, squeeze(theory_probability_array(:,:,1)))
title(['res freq = ' num2str(res_freq_GHz) 'GHz, input power at sample = ' num2str(input_power_at_sample_dBm) 'dBm'])
