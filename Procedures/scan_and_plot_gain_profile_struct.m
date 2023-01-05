input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
mkdir([cd '/d' input_params.file_name_time_stamp '_gain_profile']);
input_params.vna.power = -65;
input_params.vna.average_number = 50;
input_params.vna.IF_BW = 10e3;
input_params.vna.number_points = 1601;
input_params.vna.center = 5.76e9;
input_params.vna.span = 250e6;
input_params.vna.electrical_delay = 62.6e-9; 
input_params.flux_start = -1;
input_params.flux_stop = -0.2;
input_params.flux_points = 30;
input_params.gate_start = 2.1;
input_params.gate_stop = 2.2;
input_params.gate_points = 1;
input_params.fine_gain_profile_exclude_span = 15e6; % span around resonance to omit in extracting gain
input_params.plot_display = 1;

switch_vna_measurement(ps_2)
vna_set_average(vna, input_params.vna.average_number, 1)
vna_set_IF_BW(vna, input_params.vna.IF_BW, 1)
vna_set_sweep_points(vna, input_params.vna.number_points, 1)
vna_set_center_span(vna, input_params.vna.center, input_params.vna.span, 1)
vna_set_electrical_delay(vna, input_params.vna.electrical_delay, 1, 2)
vna_set_power(vna, input_params.vna.power)
vna_turn_output_on(vna)
disp('ensure current folder is where you want the gain profile to be saved')

% [flux_scan_1_log_mag,flux_scan_1_pos_phase,flux_scan_1_bias_values]=gate_flux_scan_with_dmm(vna,dmm_2,dmm_1,-1,-.2,30,...
% -1.3,-1.2,1,50,10e3,1,0);
[freq_measured, amp_measured, phase_measured, dc_bias_values]=gate_flux_scan_with_dmm_struct(vna,dmm_2,dmm_1,input_params.flux_start,input_params.flux_stop,input_params.flux_points,...
input_params.gate_start,input_params.gate_stop,input_params.gate_points,input_params.vna.average_number,input_params.vna.IF_BW,input_params.vna.electrical_delay,0, 0);

vna_turn_output_off(vna)
clear_instruments
save([cd '/d' input_params.file_name_time_stamp '_gain_profile/flux_scan_data.mat'])
rough_gain_prof.freq = squeeze(mean(mean(freq_measured, 1), 2)); 
rough_gain_prof.amp = squeeze(mean(mean(amp_measured, 1), 2));
rough_gain_prof.phase = squeeze(mean(mean(phase_measured, 1), 2));
data.freq = freq_measured;
data.amp = amp_measured;
data.phase = phase_measured;

clearvars -except rough_gain_prof input_params data
save([cd '/d' input_params.file_name_time_stamp '_gain_profile/rough_gain_profile_and_data.mat'])

[gain_prof.freq,gain_prof.amp,gain_prof.phase]=extract_gain_profile_v2_struct(data.freq, data.amp, data.phase, rough_gain_prof, ...
    input_params.fine_gain_profile_exclude_span, input_params.plot_display);

saveas(gcf,[cd '/d' input_params.file_name_time_stamp '_gain_profile/gain_profile.fig'])
saveas(gcf,[cd '/d' input_params.file_name_time_stamp '_gain_profile/gain_profile.png'])

clearvars -except gain_prof input_params

save([cd '/d' input_params.file_name_time_stamp '_gain_profile/gain_prof_struct.mat'])