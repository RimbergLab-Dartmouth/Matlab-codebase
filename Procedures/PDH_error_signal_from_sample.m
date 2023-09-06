if (input('verify current directory is where you want to save data\nproceed(1) or quit(0)'))
else
    return;
end

clear_workspace_connect_instruments

input_params.file_name_time_stamp = datestr(now, 'mm.dd.yyyy_HH.MM.SS');
mkdir([cd '/' input_params.file_name_time_stamp '_error_signal_acquisition']);

input_params.sig_gen_amp = -25; % dBm
input_params.center_freq = 5.7836e9; % Hz
input_params.span = 80; % MHz
input_params.freq_step = 0.2; % MHz
input_params.repetition_number = 5; % number repetitions
input_params.phase_mod_freq = 30; % MHz, modulation freq
input_params.phase_mod_amp = .1; % Vpp
input_params.phase_mod_phase = 0; % degs

%%%% Tunable Bandpass Filter params
% V = 2.32 flat range: 5.679 - 5.749 GHz
% V = 2.55 flat range: 5.746 - 5.820 GHz
% V = 2.77 flat range: 5.812 - 5.887 GHz

input_params.TBF.control_voltage_left = 2.32; %0 - 10V
input_params.TBF.control_voltage_mid = 2.55;
input_params.TBF.control_voltage_right = 2.77;

%%%% lockin params
input_params.lockin.time_constant = 1000e-3; % s,
input_params.lockin.sensitivity = 10; % in mV
input_params.lockin.ref_mode = 'ext';
input_params.lockin.ref_phase = 45; % degs
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
hp_6612c_set_voltage(ps_1,input_params.TBF.control_voltage_mid,'on');

%% notes on the tunable band pass filter
% voltage supply (pin 4) set to -15V
% voltage supply (pin 5) set to +15V
% drive control voltage (pin 1) will be initialized, range 0-10V
% heater supply (pin 6) set to 28V
% Imperial data for the tunable band pass filter obtained on 08/29/23,
% voltage and the center frequency of the passing band is as the following:
% v = [2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9] in volts
% f_center = [5.645 5.675 5.707 5.738 5.768 5.801 5.830 5.859 5.896] in GHz
% range of flatness: ~65 MHz
% based on this: recommanded voltage for 5.7845GHz is 2.55
% hp_6612c_set_voltage(ps_1,2.55,'on');


%output time estimate
disp('rough estimate:')
disp(1.2*input_params.span/input_params.freq_step*(input_params.repetition_number * 5 * input_params.lockin.time_constant)/60)
disp('minutes')

%initialize arrays 
data.probe_freq = -input_params.span/2 : input_params.freq_step : input_params.span/2;
data.lockin_x_quadrature = zeros(length(data.probe_freq), input_params.repetition_number);
data.lockin_y_quadrature = data.lockin_x_quadrature;

for m_rep = 1 : input_params.repetition_number
    tic
    for m_freq = 1 : length(data.probe_freq)
        if data.probe_freq(m_freq) < -35 % set TBF to appropriate range
            hp_6612c_set_voltage(ps_1,input_params.TBF.control_voltage_left,'on');
        elseif data.probe_freq(m_freq) <= 35
            hp_6612c_set_voltage(ps_1,input_params.TBF.control_voltage_mid,'on');
        else
            hp_6612c_set_voltage(ps_1,input_params.TBF.control_voltage_right,'on');
        end
        n5183b_set_frequency(keysight_sg, input_params.center_freq+data.probe_freq(m_freq)*1e6);
        pause(5 * input_params.lockin.time_constant);
        data.lockin_x_quadrature(m_freq, m_rep) = sr844_lockin_query_measured_value(lockin_sr844,'X');
        data.lockin_y_quadrature(m_freq, m_rep) = sr844_lockin_query_measured_value(lockin_sr844,'Y');
    end
    fprintf('rep %i: ellapsed time is %.3g minutes \n', m_rep, toc/60);
end

%%%% mean of repetitions
analysis.lockin_x_mean = mean(data.lockin_x_quadrature, 2);
analysis.lockin_y_mean = mean(data.lockin_y_quadrature, 2);

clear_instruments

save([cd '/' input_params.file_name_time_stamp '_error_signal_acquisition/error_signal_data.mat'])

freq_vs_x_quad_fig = figure;
p = plot(data.probe_freq, analysis.lockin_x_mean/1e3, '.');
p.MarkerSize = 20;
xlabel('$\omega_c - \omega_0$ (MHz)', 'interpreter', 'latex')
ylabel('X (mV)', 'interpreter', 'latex')
% savefig(freq_vs_x_quad_fig, 'freq_vs_x_quadrature.fig')
saveas(gcf,[cd '/' input_params.file_name_time_stamp '_error_signal_acquisition/x.fig'])
saveas(gcf,[cd '/' input_params.file_name_time_stamp '_error_signal_acquisition/x.png'])

freq_vs_y_quad_fig = figure;
p = plot(data.probe_freq, analysis.lockin_y_mean/1e3, '.');
p.MarkerSize = 20;
xlabel('$\omega_c - \omega_0$ (MHz)', 'interpreter', 'latex')
ylabel('Y (mV)', 'interpreter', 'latex')
% savefig(freq_vs_y_quad_fig, 'freq_vs_y_quadrature.fig')
saveas(gcf,[cd '/' input_params.file_name_time_stamp '_error_signal_acquisition/y.fig'])
saveas(gcf,[cd '/' input_params.file_name_time_stamp '_error_signal_acquisition/y.png'])

%%
x_quad_fig_vs_y_quad = figure;
hold on
colors = parula(length(analysis.lockin_x_mean));
for m_test = 1 : length(colors)
    plot(analysis.lockin_x_mean(m_test)/1e3, analysis.lockin_y_mean(m_test)/1e3, 'o', 'color', colors(m_test, :))
end
xlabel('X (mV)', 'interpreter', 'latex')
ylabel('Y (mV)', 'interpreter', 'latex')
saveas(gcf,[cd '/' input_params.file_name_time_stamp '_error_signal_acquisition/xy.fig'])
saveas(gcf,[cd '/' input_params.file_name_time_stamp '_error_signal_acquisition/xy.png'])
