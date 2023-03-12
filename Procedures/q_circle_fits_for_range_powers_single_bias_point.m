%% input params
if ~exist('gain_prof', 'var')
   load_directory = uigetdir('enter directory where gain_prof_struct.mat is saved');
   load([load_directory '\gain_prof_struct.mat'], 'gain_prof')
   clear load_directory
end
if ~exist('bias_point', 'var')
   load_directory = uigetdir('enter directory where bias_point_struct.mat is saved');
   load([load_directory '\bias_point_struct.mat'], 'bias_point')
   clear load_directory
end
input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
input_params.save_fig_param = 1;
input_params.fridge_attenuation = 85.6; % dB
input_params.flux_bias = 0.25;
input_params.gate_bias = 0;
mkdir([cd '/d' input_params.file_name_time_stamp '_power_scan_flux_' num2str(input_params.flux_bias) '_ng_' num2str(input_params.gate_bias)]);
input_params.number_power = 30;
input_params.power_start_dBm = -70;
input_params.power_stop_dBm = -25;
input_params.power_step_mode = 'log'; % 'linear'
input_params.flux_series_resistor = 11.2e3;
input_params.desired_flux_bias = 0; %units of phi_0
input_params.desired_gate_bias = 0;   %units of ng
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
input_params.plot_visible = 0;
%% set VNA params
switch_vna_measurement
vna_set_average(vna, input_params.vna.average_number, 1)
vna_set_IF_BW(vna, input_params.vna.IF_BW, 1)
vna_set_sweep_points(vna, input_params.vna.number_points, 1)
vna_set_center_span(vna, input_params.vna.center, input_params.vna.span, 1)
vna_set_electrical_delay(vna, input_params.vna.electrical_delay, 1, 2)
if isfield(input_params.vna, 'smoothing_aperture_amp')
    vna_set_smoothing_aperture(vna, 1, 1, input_params.vna.smoothing_aperture_amp)
    vna_turn_smoothing_on_off(vna, 1, 1, 'on')
end
if isfield(input_params.vna, 'smoothing_aperture_phase')
    vna_set_smoothing_aperture(vna, 1, 1, input_params.vna.smoothing_aperture_phase)
    vna_turn_smoothing_on_off(vna, 1, 2, 'on')
end
%%%%%%%%%%%
%% do power scan %%%%%%%%%
number_power = input_params.number_power;
number_gate = 1;
disp('running power scan')
[power_scan.freq, power_scan.amp, power_scan.phase, power_scan.freq_zoom, power_scan.amp_zoom, power_scan.phase_zoom, power_scan.power_values, power_scan.dc_bias]=...
power_scan_zoom_resonance_at_single_cCPT_bias_point(vna,dmm_2,dmm_1,input_params.flux_bias, input_params.gate_bias, input_params.power_start_dBm, ...
input_params.power_stop_dBm, number_power, gain_prof, bias_point, input_params.power_step_mode, input_params.vna);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% fit q circles to power scan
[power_scan.fits.resonance_fits,power_scan.fits.data_real,power_scan.fits.data_imag,power_scan.fits.theory_real,power_scan.fits.theory_imag,~,power_scan.fits.err] = ...
    resonance_fit_to_range_of_bias_data_with_freq_flucs_struct (power_scan,gain_prof,1);

res_freqs_power = power_scan.fits.resonance_fits(:,1);
gamma_ints_power = power_scan.fits.resonance_fits(:,2);
gamma_exts_power = power_scan.fits.resonance_fits(:,3);
sigmas_power = power_scan.fits.resonance_fits(:,4);
flux_values_power = squeeze(power_scan.dc_bias(:,2))*input_params.flux_series_resistor/1e6; % convert from uA to V
gate_value_power = mean(squeeze(power_scan.dc_bias(:,1)))/10;
powers = power_scan.power_values;
%% capture final res freq
connect_instruments
disp('capturing VNA data at single photon power')
switch_vna_measurement
pause(2)
vna_set_power(vna, -65, 1)
vna_set_electrical_delay(vna, input_params.vna.electrical_delay, 1, 2);
vna_turn_output_on(vna)
vna_set_IF_BW(vna, input_params.vna.IF_BW, 1)
vna_set_sweep_points(vna, input_params.vna.number_points, 1)
vna_set_center_span(vna, input_params.vna.center, input_params.vna.span, 1)
vna_send_average_trigger(vna);
[data.vna.single_photon.final.rough.freq, ...
        data.vna.single_photon.final.rough.amp] = ...
        vna_get_data(vna, 1, 1);
[~, data.vna.single_photon.final.rough.phase] = ...
        vna_get_data(vna, 1, 2);
[~,manual_index] = min(squeeze(data.vna.single_photon.final.rough.amp) ...
        - gain_prof.amp);
rough_resonance = squeeze(data.vna.single_photon.final.rough.freq(1,manual_index));
data.vna.single_photon.final.rough_resonance = squeeze(data.vna.single_photon.final.rough.freq(1, manual_index));
data.vna.single_photon.final.res_freq_shift_during_run = data.vna.single_photon.final.rough_resonance  - ...
    res_freqs_power(1);
vna_set_center_span(vna,rough_resonance,input_params.vna.span_zoom,1);
clear manual_index ...
      rough_resonance
vna_set_IF_BW(vna, input_params.vna.IF_BW_zoom, 1)
vna_set_average(vna, input_params.vna.average_number_zoom, 1, 1);
vna_set_sweep_points(vna, input_params.vna.number_points_zoom, 1);
vna_send_average_trigger(vna);
[data.vna.single_photon.final.fine.freq, ...
        data.vna.single_photon.final.fine.amp] = ...
        vna_get_data(vna, 1, 1);
[~, data.vna.single_photon.final.fine.phase] = ...
        vna_get_data(vna, 1, 2);
[~,min_index] = min(squeeze(data.vna.single_photon.final.fine.amp));
%     rough_resonance = 5.813e9;
data.vna.single_photon.final.fine.min_amp_freq  = squeeze(data.vna.single_photon.final.fine.freq(min_index));
data.vna.single_photon.final.fine.res_freq_shift_during_run = data.vna.single_photon.final.fine.min_amp_freq  - ...
    res_freqs_power(1);
disp(['start freq = ' num2str(res_freqs_power(1)/1e9) 'GHz, final freq = ' ...
    num2str(squeeze(data.vna.single_photon.final.fine.min_amp_freq )/1e9) 'GHz. ' 13 10 ...
    'freq shift during run = ' num2str((res_freqs_power(1) - ...
    squeeze(data.vna.single_photon.final.fine.min_amp_freq ))/1e6) 'MHz'])
clear min_index
pause(3);
vna_turn_output_off(vna)
clear_instruments
%% Plot internal damping rate figure    
if input_params.plot_visible == 1
    power_vs_kappa_int = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
elseif input_params.plot_visible == 0 
    power_vs_kappa_int = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
end
if strcmp(input_params.power_step_mode, 'linear')
    plot(powers/convert_dB_to_fraction(input_params.fridge_attenuation)*1e9, gamma_ints_power/1e6, 'o', 'markersize', 5)
    xlabel('$P_{\mathrm{in}}$ (aW)', 'interpreter', 'latex')
elseif strcmp(input_params.power_step_mode, 'log')
    plot(powers - input_params.fridge_attenuation, gamma_ints_power/1e6, 'o', 'markersize', 5)
    xlabel('$P_{\mathrm{in}}$ (dBm)', 'interpreter', 'latex')
end
ylabel('$\kappa_{\mathrm{int}}$ (MHz)', 'interpreter', 'latex')
title(['Internal damping rate vs drive power at $n_g$ = ' num2str(round(input_params.gate_bias, 2)) 'elns, $\Phi_{\mathrm{ext}}$ = ' ...
    num2str(round(input_params.flux_bias, 2)) '$\Phi_0$'], 'interpreter', 'latex')
if input_params.save_fig_param == 1
    save_file_name = [cd '/d' input_params.file_name_time_stamp '_power_scan_flux_' num2str(input_params.flux_bias) '_ng_' num2str(input_params.gate_bias) ...
        '/ng_' num2str(input_params.gate_bias) ...
        '_flux_' num2str(input_params.flux_bias*1000) 'm_power_scan_internal_damping_rate.png'];
    saveas(power_vs_kappa_int, save_file_name)
end
if input_params.save_fig_param == 1
    save_file_name = [cd '/d' input_params.file_name_time_stamp '_power_scan_flux_' num2str(input_params.flux_bias) '_ng_' num2str(input_params.gate_bias) ...
        '/ng_' num2str(input_params.gate_bias) ...
        '_flux_' num2str(input_params.flux_bias*1000) 'm_power_scan_internal_damping_rate.fig'];
    saveas(power_vs_kappa_int, save_file_name)
end
%% Plot res freq figure    
if input_params.plot_visible == 1
    power_vs_res_freq = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
elseif input_params.plot_visible == 0 
    power_vs_res_freq = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
end
if strcmp(input_params.power_step_mode, 'linear')
    plot(powers/convert_dB_to_fraction(input_params.fridge_attenuation)*1e9, res_freqs_power/1e9, 'o', 'markersize', 5)
    xlabel('$P_{\mathrm{in}}$ (aW)', 'interpreter', 'latex')
elseif strcmp(input_params.power_step_mode, 'log')
    plot(powers - input_params.fridge_attenuation, res_freqs_power/1e9, 'o', 'markersize', 5)
    xlabel('$P_{\mathrm{in}}$ (dBm)', 'interpreter', 'latex')
end
ylabel('$\omega_0$ (GHz)', 'interpreter', 'latex')
title(['Res freq vs drive power at $n_g$ = ' num2str(round(input_params.gate_bias, 2)) 'elns, $\Phi_{\mathrm{ext}}$ = ' ...
    num2str(round(input_params.flux_bias, 2)) '$\Phi_0$'], 'interpreter', 'latex')
if input_params.save_fig_param == 1
    save_file_name = [cd '/d' input_params.file_name_time_stamp '_power_scan_flux_' num2str(input_params.flux_bias) '_ng_' num2str(input_params.gate_bias) ...
        '/ng_' num2str(input_params.gate_bias) ...
        '_flux_' num2str(input_params.flux_bias*1000) 'm_power_scan_res_freq.png'];
    saveas(power_vs_res_freq, save_file_name)
end
if input_params.save_fig_param == 1
    save_file_name = [cd '/d' input_params.file_name_time_stamp '_power_scan_flux_' num2str(input_params.flux_bias) '_ng_' num2str(input_params.gate_bias) ...
        '/ng_' num2str(input_params.gate_bias) ...
        '_flux_' num2str(input_params.flux_bias*1000) 'm_power_scan_res_freq.fig'];
    saveas(power_vs_res_freq, save_file_name)
end
clear power_vs_res_freq ...
      save_file_name
clearvars -except power_scan ...
                  bias_point ...
                  input_params ...
                  gain_prof
%% save data              
save([cd '/d' input_params.file_name_time_stamp '_power_scan_flux_' num2str(input_params.flux_bias) '_ng_' num2str(input_params.gate_bias) ...
    '/power_scan_data.mat'])
clearvars -except power_scan input_params
save([cd '/d' input_params.file_name_time_stamp '_power_scan_flux_' num2str(input_params.flux_bias) '_ng_' num2str(input_params.gate_bias) ...
    '/power_scan_only_useful.mat'])              