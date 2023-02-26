clc
clear_workspace_connect_instruments

input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
mkdir([cd '/d' input_params.file_name_time_stamp '_error_signal_acquisition']);

input_params.sig_gen_amp = -25; % dBm
input_params.center_freq = 5.7845e9; % Hz
input_params.span = 40; % MHz
input_params.freq_step = 0.4; % MHz
input_params.repetition_number = 1; % number repetitions
input_params.phase_mod_freq = 30; % MHz, modulation freq
input_params.phase_mod_amp = .1; % Vpp
input_params.phase_mod_phase = 0; % degs

%%%% lockin params
input_params.lockin.time_constant = 300e-3; % s,
input_params.lockin.sensitivity = 10; % in mV
input_params.lockin.ref_mode = 'ext';
input_params.lockin.ref_phase = 0; % degs
%%%% Novatech params
input_params.novatech.phase_modulation_channel = 0; % channel number - 0 - 3
input_params.novatech.lockin_ref_channel = 1; % channel number - 0 - 3
input_params.novatech.lockin_ref_amp = 1; % Vpp
input_params.novatech.lockin_ref_phase = 0 ; % degs

switch_PDH_measurement(keysight_sg, ps_2)

%% set instruments
sr844_lockin_set_time_constant(lockin_sr844, input_params.lockin.time_constant);
sr844_lockin_set_sensitivity(lockin_sr844, input_params.lockin.sensitivity);
sr844_lockin_set_ref_mode(lockin_sr844, input_params.lockin.ref_mode);
sr844_lockin_set_ref_phase_degs(lockin_sr844, input_params.lockin.ref_phase);
novatech_set_phase(novatech,input_params.phase_mod_phase,input_params.novatech.phase_modulation_channel);
novatech_set_freq(novatech,input_params.phase_mod_freq,input_params.novatech.phase_modulation_channel);
novatech_set_phase(novatech,input_params.novatech.lockin_ref_phase,input_params.novatech.lockin_ref_channel);
novatech_set_freq(novatech,input_params.phase_mod_freq,input_params.novatech.lockin_ref_channel);
n5183b_set_amplitude(keysight_sg, input_params.sig_gen_amp)
n5183b_toggle_output(keysight_sg, 'on')

%initialize arrays 
data.probe_freq = -input_params.span/2 : input_params.freq_step : input_params.span/2;
data.lockin_x_quadrature = zeros(length(data.probe_freq), input_params.repetition_number);
data.lockin_y_quadrature = data.lockin_x_quadrature;

for m_freq = 1 : length(data.probe_freq)
    for m_rep = 1 : input_params.repetition_number
		n5183b_set_frequency(keysight_sg, input_params.center_freq+data.probe_freq(m_freq)*1e6)
        pause(5 * input_params.lockin.time_constant);
        data.lockin_x_quadrature(m_freq, m_rep) = sr844_lockin_query_measured_value(lockin_sr844,'X');
        data.lockin_y_quadrature(m_freq, m_rep) = sr844_lockin_query_measured_value(lockin_sr844,'Y');
    end
end

%%%% mean of repetitions
analysis.lockin_x_mean = mean(data.lockin_x_quadrature, 2);
analysis.lockin_y_mean = mean(data.lockin_y_quadrature, 2);

clear_instruments

save([cd '/d' input_params.file_name_time_stamp '_error_signal_acquisition/error_signal_data.mat'])

freq_vs_x_quad_fig = figure;
plot(data.probe_freq, analysis.lockin_x_mean/1e3)
xlabel('$\omega_c - \omega_0$ (MHz)', 'interpreter', 'latex')
ylabel('X (mV)', 'interpreter', 'latex')
% savefig(freq_vs_x_quad_fig, 'freq_vs_x_quadrature.fig')


freq_vs_y_quad_fig = figure;
plot(data.probe_freq, analysis.lockin_y_mean/1e3)
xlabel('$\omega_c - \omega_0$ (MHz)', 'interpreter', 'latex')
ylabel('Y (mV)', 'interpreter', 'latex')
% savefig(freq_vs_y_quad_fig, 'freq_vs_y_quadrature.fig')
%%
x_quad_fig_vs_y_quad = figure;
hold on
colors = parula(length(analysis.lockin_x_mean));
for m_test = 1 : length(colors)
    plot(analysis.lockin_x_mean(m_test)/1e3, analysis.lockin_y_mean(m_test)/1e3, 'o', 'color', colors(m_test, :))
end
xlabel('X (mV)', 'interpreter', 'latex')
ylabel('Y (mV)', 'interpreter', 'latex')
% savefig(x_quad_fig_vs_y_quad, 'x_quadrature_vs_y_quadrature.fig')