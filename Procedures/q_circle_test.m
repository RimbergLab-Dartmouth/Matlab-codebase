if (input('verify current directory is where you want to save data\nproceed(1) or quit(0)'))
else
    return;
end

if ~exist('gain_prof', 'var')
   fprintf('enter directory where gain_prof_struct.mat is saved \n');
   load_directory = uigetdir('enter directory where gain_prof_struct.mat is saved');
   load([load_directory '\gain_prof_struct.mat'], 'gain_prof')
   clear load_directory
end

if (input('proceed with current bias point(1) or specify new (0)'))
else
    [desired_gate_point, desired_flux_point] = input('enter [desired_gate_point, desired_flux_point] ');
    set_bias_point(desired_gate_point,desired_flux_point);
end


connect_instruments;

input_params.file_name_time_stamp = datestr(now, 'mm.dd.yyyy_HH.MM.SS');
mkdir([cd '/' input_params.file_name_time_stamp '_single_q_circle']);
input_params.number_gate = 1;
input_params.number_flux = 1;
input_params.gate_voltage_status = dmm_get_voltage(dmm_1);
input_params.flux_voltage_status = dmm_get_voltage(dmm_2);
input_params.flux_series_resistor = 11.2e3;
input_params.vna.power = -65;
input_params.vna.average_number = 35;
input_params.vna.IF_BW = 10e3; %Hz
input_params.vna.smoothing_aperture_amp = 1; % percent
input_params.vna.smoothing_aperture_phase = 1.5; % percent
input_params.vna.number_points = 1601;
input_params.vna.average_number_zoom = 50;
input_params.vna.IF_BW_zoom = 1e3; %Hz
input_params.vna.number_points_zoom = 201;
input_params.vna.center = 5.76e9;  %Hz
input_params.vna.span = 250e6;  %Hz
input_params.vna.span_zoom = 20e6; % Hz
input_params.vna.electrical_delay = 62.6e-9;  %s

%%% set VNA params
switch_vna_measurement
vna_set_average(vna, input_params.vna.average_number, 1)
vna_set_IF_BW(vna, input_params.vna.IF_BW, 1)
vna_set_sweep_points(vna, input_params.vna.number_points, 1)
vna_set_center_span(vna, input_params.vna.center, input_params.vna.span, 1)
vna_set_electrical_delay(vna, input_params.vna.electrical_delay, 1, 2)
vna_set_power(vna, input_params.vna.power)
if isfield(input_params.vna, 'smoothing_aperture_amp')
    vna_set_smoothing_aperture(vna, 1, 1, input_params.vna.smoothing_aperture_amp)
    vna_turn_smoothing_on_off(vna, 1, 1, 'on')
end
if isfield(input_params.vna, 'smoothing_aperture_phase')
    vna_set_smoothing_aperture(vna, 1, 1, input_params.vna.smoothing_aperture_phase)
    vna_turn_smoothing_on_off(vna, 1, 2, 'on')
end
%%%%%%%%%%%

gate_value = input_params.gate_voltage_status * 100;
flux_value = input_params.flux_voltage_status;

[scan.freq, scan.amp, scan.phase, scan.freq_zoom, scan.amp_zoom, scan.phase_zoom, scan.dc_bias]=...
flux_gate_scan_zoom_resonance_struct(vna,dmm_2,dmm_1,flux_value,flux_value + 1, 1,...
gate_value, gate_value + 1, 1, gain_prof, input_params.vna);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[scan.fits.resonance_fits,scan.fits.data_real,scan.fits.data_imag,scan.fits.theory_real,scan.fits.theory_imag,~,scan.fits.err] = ...
    resonance_fit_to_range_of_bias_data_with_freq_flucs_struct (scan, gain_prof, 2, 'flucs_and_angle');

saveas(gcf,[cd '/' input_params.file_name_time_stamp '_single_q_circle/single_q_circle.fig'])
saveas(gcf,[cd '/' input_params.file_name_time_stamp '_single_q_circle/single_q_circle.png'])
save([cd '/' input_params.file_name_time_stamp '_single_q_circle/input_params.mat'], 'input_params')
save([cd '/' input_params.file_name_time_stamp '_single_q_circle/scan.mat'], 'scan')