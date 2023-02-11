% Assumes using N5183B as the LO, and the FG mode of the AWG520
%% input params
input_params.start_amp = -25;
input_params.number_points = 10;
input_params.stop_amp = 3;
input_params.amp_units = 'dBm';

input_params.awg.freq = 84e6;
input_params.LO.freq = 5.686e9;
input_params.LO.power = 17; % dBm
input_params.sa.span = 1e3; % Hz
input_params.sa.RBW = 1; % Hz
input_params.sa.number_points = 1001;
input_params.sa.average_number = 3;
input_params.sa.average_type = 'RMS';
input_params.sa.trace_type = 'average';

input_params.save_data = 1;
input_params.figures_visible = 1;
input_params.save_plots = 1;
%% make directory
input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
input_params.file_directory = [cd '/d' input_params.file_name_time_stamp '_AWG_additional_attenuation_calibration'];
mkdir(input_params.file_directory);
%% set SA 
fclose(sa)
sa.InputBufferSize = 100000001;
fopen(sa)
set(sa,'Timeout',1000)
n9000_set_sweep_points(sa, input_params.sa.number_points)
n9000_set_RBW(sa,input_params.sa.RBW)
n9000_set_trace_type(sa,input_params.sa.trace_type)
n9000_set_average_type(sa, input_params.sa.average_type)
n9000_set_average_number(sa, input_params.sa.average_number)
n9000_set_detector_type(sa, 'pos')  % sets to peak detection
n9000_set_center_span(sa, input_params.LO.freq + input_params.awg.freq, input_params.sa.span)
n9000_set_RBW(sa, input_params.sa.RBW)
%% set AWG and LO tone 
awg_toggle_output(awg, 'off', 1)
awg_toggle_output(awg, 'off', 2)
n5183b_toggle_output(keysight_sg, 'off')
awg_FG_state_on(awg, 'on')

awg_FG_set_freq(awg, input_params.awg.freq)
n5183b_set_frequency(keysight_sg, input_params.LO.freq)
n5183b_set_amplitude(keysight_sg, input_params.LO.power)
%% generate test amps and run loop
input_params.amp_test_points = linspace(input_params.start_amp, input_params.stop_amp, input_params.number_points);
awg_toggle_output(awg, 'on', 1)
for m_loop = 1 : length(input_params.amp_test_points)
    awg_FG_set_amp(awg, input_params.amp_test_points(m_loop), 1, 'dBm')
    [marker_freq, marker_amp] = n9000_marker_peak_search(sa);
    data.output_power (m_loop) = marker_amp;
    data.output_freq (m_loop) = marker_freq;
end
clear marker_freq ...
      marker_amp ...
      m_loop ...
      ans
%% turn off all sources
awg_toggle_output(awg, 'off', 1)
awg_toggle_output(awg, 'off', 2)
n5183b_toggle_output(keysight_sg, 'off')
%% fit linear
analysis.fit_coeffs = polyfit(input_params.amp_test_points, data.output_power, 1);
analysis.fit_output = analysis.fit_coeffs(1) .* input_params.amp_test_points + analysis.fit_coeffs(2);
analysis.additional_attenuation = analysis.fit_coeffs(2);
%% save data
if input_params.save_data
    clear_instruments
    save([input_params.file_directory '/gain_added_noise_data.mat'])
end
%% plot data
if input_params.figures_visible == 1 
    attenuation_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
else
    attenuation_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
end
plot(input_params.amp_test_points, data.output_power, 'o', 'markerSize', 6, 'DisplayName', 'data', 'color', 'b')
hold on
plot(input_params.amp_test_points, analysis.fit_output, 'linewidth', 3, 'DisplayName', 'fit', 'color', 'b')
xlabel('Input Power (dBm)', 'interpreter', 'latex')
ylabel('Output Power (dBm)', 'interpreter', 'latex')
title(datestr(now, 'yy/mm/dd HH:MM:SS'))
if input_params.save_plots
    saveas(attenuation_figure, [input_params.file_directory '/input_vs_output_power.fig'])
    saveas(attenuation_figure, [input_params.file_directory '/input_vs_output_power.png'])
end