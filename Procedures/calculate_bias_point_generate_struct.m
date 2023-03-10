if ~exist('gain_prof', 'var')
   load_directory = uigetdir('enter directory where gain_prof_struct.mat is saved');
   load([load_directory '\gain_prof_struct.mat'], 'gain_prof')
   clear load_directory
end
input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
mkdir([cd '/d' input_params.file_name_time_stamp '_bias_point']);
input_params.number_gate = 30;
input_params.number_flux = 14;
input_params.gate_start = -5;
input_params.gate_stop = 5;
input_params.flux_start = -.7;
input_params.flux_stop = .3;
input_params.flux_series_resistor = 11.2e3;
input_params.desired_flux_bias = 0; %units of phi_0
input_params.desired_gate_bias = 0;   %units of ng
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

%%% do flux scan %%%%%%%%%
number_flux = input_params.number_flux;
number_gate = 1;
gate_start = input_params.gate_start;
gate_stop = gate_start + 1;
disp('running flux period calculator')
[flux_scan.freq, flux_scan.amp, flux_scan.phase, flux_scan.freq_zoom, flux_scan.amp_zoom, flux_scan.phase_zoom, flux_scan.dc_bias]=...
flux_gate_scan_zoom_resonance_struct(vna,dmm_2,dmm_1,input_params.flux_start,input_params.flux_stop,(input_params.flux_stop - input_params.flux_start)/number_flux,...
gate_start,gate_stop,(gate_stop + 3 - gate_start)/number_gate, gain_prof, input_params.vna);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[flux_scan.fits.resonance_fits,flux_scan.fits.data_real,flux_scan.fits.data_imag,flux_scan.fits.theory_real,flux_scan.fits.theory_imag,~,flux_scan.fits.err] = ...
    resonance_fit_to_range_of_bias_data_with_freq_flucs_struct (flux_scan,gain_prof,1);

res_freqs_flux = flux_scan.fits.resonance_fits(:,1);
gamma_ints_flux = flux_scan.fits.resonance_fits(:,2);
gamma_exts_flux = flux_scan.fits.resonance_fits(:,3);
sigmas_flux = flux_scan.fits.resonance_fits(:,4);
flux_values_flux = squeeze(flux_scan.dc_bias(:,:,2))*input_params.flux_series_resistor/1e6; % convert from uA to V
gate_value_flux = mean(squeeze(flux_scan.dc_bias(:,:,1)))/10;

figure
plot(flux_values_flux,res_freqs_flux,'o','DisplayName','data')
xlabel('Flux input voltage (V)')
ylabel('Resonant Freqs (Hz)')
title('Raw data, flux sweep')

[flux_scan.fits.flux_period,flux_scan.fits.flux_offset,flux_scan.fits.flux_center_freq_mean, flux_scan.fits.offset_slope] = ...
    identify_flux_period_and_offset_struct(res_freqs_flux,flux_values_flux,gate_value_flux,1);

flux_scan.fits.flux_zero_voltage = flux_scan.fits.flux_offset - (-1)^flux_scan.fits.offset_slope*flux_scan.fits.flux_period/4;
flux_zero_voltage = flux_scan.fits.flux_zero_voltage;

%%%% do a gate scan %%%%%%%%%
number_flux = 1;
number_gate = input_params.number_gate;
flux_start = flux_zero_voltage;
flux_stop = flux_zero_voltage+1;
disp('running gate period calculator')

[gate_scan.freq, gate_scan.amp, gate_scan.phase, gate_scan.freq_zoom, gate_scan.amp_zoom, gate_scan.phase_zoom, gate_scan.dc_bias]= ...
flux_gate_scan_zoom_resonance_struct(vna,dmm_2,dmm_1,flux_start,flux_stop,(flux_stop - flux_start)/number_flux,...
input_params.gate_start,input_params.gate_stop,(input_params.gate_stop - input_params.gate_start)/number_gate, gain_prof, input_params.vna);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[gate_scan.fits.resonance_fits_gate,gate_scan.fits.data_real_gate,gate_scan.fits.data_imag_gate,gate_scan.fits.theory_real_gate,gate_scan.fits.theory_imag_gate,~,gate_scan.fits.err_gate] = ...
    resonance_fit_to_range_of_bias_data_with_freq_flucs_struct (gate_scan, gain_prof, 1);

res_freqs_gate = gate_scan.fits.resonance_fits_gate(:,1);
gamma_ints_gate = gate_scan.fits.resonance_fits_gate(:,2);
gamma_exts_gate = gate_scan.fits.resonance_fits_gate(:,3);
sigmas_gate = gate_scan.fits.resonance_fits_gate(:,4);
flux_value_gate = mean(squeeze(gate_scan.dc_bias(:,:,2)))*input_params.flux_series_resistor;
gate_values_gate = squeeze(gate_scan.dc_bias(:,:,1));

figure
plot(gate_values_gate,res_freqs_gate,'o','DisplayName','data')
hold on
plot(gate_values_gate, 5.802e9*gate_values_gate./gate_values_gate, '--', 'displayName', 'cutoff for fit')
xlabel('Gate input Voltage (V)')
ylabel('Resonant Freqs (Hz)')
title('Raw data, gate sweep')
legend show
number_even = input('how many even bands do you see?');
number_odd = input('how many odd bands do you see?');
start_even_or_odd = input('is the band on the extreme left even (0) or odd (1)?');

[gate_scan.qp.resonance_freqs_no_qp,gate_scan.qp.gate_values_no_qp]=identify_qp_region_single_flux_bias_struct(res_freqs_gate,gate_values_gate, number_odd, start_even_or_odd);

[gate_period,gate_offset,vertex_offset,concavity]=identify_gate_period_and_offset_struct(gate_scan.qp.resonance_freqs_no_qp,ones(length(gate_scan.qp.resonance_freqs_no_qp),1), ...
    flux_value_gate, gate_scan.qp.gate_values_no_qp, flux_scan.fits.flux_center_freq_mean,number_even,1);
gate_period = gate_period/10;
gate_offset = gate_offset/10;

clear_instruments

bias_point.flux_zero_voltage = flux_zero_voltage;
bias_point.flux_period = flux_scan.fits.flux_period;
bias_point.gate_offset = gate_offset;
bias_point.gate_period = gate_period;
bias_point.flux_center_freq_mean = flux_scan.fits.flux_center_freq_mean;
clearvars -except gate_scan ...
    flux_scan ...
    bias_point ...
    input_params ...
    gain_prof

save([cd '/d' input_params.file_name_time_stamp '_bias_point/bias_point_calculator_data.mat'])
clearvars -except bias_point input_params
save([cd '/d' input_params.file_name_time_stamp '_bias_point/bias_point_struct.mat'])
