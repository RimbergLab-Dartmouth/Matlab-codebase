% Assumes using N5183B as the LO, and the FG mode of the AWG520
% having correctly setup the input to the phase measurement lines, feed the
% input cable going into fridge to the spectrum analyzer instead
%% input params
input_params.start_amp = -25;
input_params.number_points = 10;
input_params.stop_amp = 3;
input_params.amp_units = 'dBm';
input_params.awg_mode = 'AWG';
%%%% if using AWG mode
input_params.awg_directory = [datestr(now, 'yy_mm_dd') '_test'];
input_params.awg.clock = 840e6; % the code is designed for this to be at 840MS/s

input_params.awg.freq = 84e6;
input_params.LO.freq = 5.686e9;
input_params.LO.power = 17; % dBm
input_params.sa.span = 1e3; % Hz
input_params.sa.RBW = 1; % Hz
input_params.sa.number_points = 1001;
input_params.sa.average_number = 5;
input_params.sa.average_type = 'RMS';
input_params.sa.trace_type = 'average';

input_params.save_data = 1;
input_params.figures_visible = 1;
input_params.save_plots = 1;
%% make directory
input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
if strcmp(input_params.awg_mode, 'FG')
    input_params.file_directory = [cd '/d' input_params.file_name_time_stamp '_FG_additional_attenuation_calibration'];
elseif strcmp(input_params.awg_mode, 'AWG')
    input_params.file_directory = [cd '/d' input_params.file_name_time_stamp '_AWG_additional_attenuation_calibration'];
end
mkdir(input_params.file_directory);
%% switch to phase measurement line
switch_phase_measurement
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
if strcmp(input_params.awg_mode, 'FG')
    awg_FG_state_on(awg, 'on')
    awg_FG_set_freq(awg, input_params.awg.freq)
elseif strcmp(input_params.awg_mode, 'AWG')
    awg_FG_state_on(awg, 'off')
    awg_change_directory(awg, '/')
    awg_create_directory(awg, input_params.awg_directory)
    awg_change_directory(awg, input_params.awg_directory)
end
n5183b_set_frequency(keysight_sg, input_params.LO.freq)
n5183b_set_amplitude(keysight_sg, input_params.LO.power)
%% generate test amps and run loop
input_params.amp_test_points = linspace(input_params.start_amp, input_params.stop_amp, input_params.number_points);
awg_toggle_output(awg, 'on', 1)
n5183b_toggle_output(keysight_sg, 'on')
for m_loop = 1 : length(input_params.amp_test_points)
    disp(['running power number ' num2str(m_loop) ' of ' num2str(length(input_params.amp_test_points))])
    if strcmp(input_params.awg_mode, 'FG')
        awg_FG_set_amp(awg, input_params.amp_test_points(m_loop), 1, 'dBm')
    elseif strcmp(input_params.awg_mode, 'AWG')
        data.awg.wfm_file = [num2str(round(input_params.amp_test_points(m_loop), 2)) 'dBm_10us_steady_marker_on'];
        file_list = awg_list_files(awg);
        if contains(file_list, data.awg.wfm_file)
            awg_delete_file(awg, data.awg.wfm_file)
        end
        [time_axis, waveform, dummy_marker] = ...
            generate_steady_on_with_defined_markers(input_params.awg.clock, input_params.awg.freq, ...
                    input_params.amp_test_points(m_loop), 10, 1);
        [~] = send_waveform_awg520(awg, time_axis, waveform, dummy_marker, ...
                data.awg.wfm_file);
        clear time_axis ...
              waveform ...
              dummy_marker ...
              file_list
        %%%% setup AWG with desired waveform
        disp('setting AWG')
        awg_load_waveform(awg, 1, [data.awg.wfm_file '.wfm'])
        awg_set_ref_source(awg, 'ext')
        awg_set_run_mode(awg, 'cont')
        awg_toggle_output(awg, 'on', 1)
        awg_set_trig_source(awg, 'ext')
        awg_run_output_channel_off(awg, 'run')
    end
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
awg_run_output_channel_off(awg, 'stop')
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

%% generate waveform function
function [time_axis, waveform_data, marker_data] = ...
    generate_steady_on_with_defined_markers(awg_clock,IF_waveform_freq, amplitude_in_dBm, waveform_time_us, marker_2_value, phase)

    % amplitude of -1000 dBm generates a waveform with all zeros (do nothing pulse)
    % awg_clock is AWG sampling rate in S/s
    % all times in us.
    % sin wave generated at 84MHz
    % waveofrm_time_us is the length of sin wave generated
    % phase in degs
    % outputs a time series, desired waveform and the appropriate markers -
    % marker 1 - irrelevant, all 0s.
    % marker 2 - data acquisition trigger - specified by marker_2_value to be 0 or 1 throughout waveform
    if ~exist('phase','var')
        phase = 0;
    end
    
    if mod(awg_clock, IF_waveform_freq) ~= 0
        disp('IF waveform for input IQ4509 mixer needs to be fixed')
    end
    
    if mod(waveform_time_us, 1) ~= 0
        disp('recording time must be a whole number in us')
        return
    end 
    if mod(awg_clock/1e6, 1) ~= 0
        disp('AWG needs to be a whole number in MS/s')
        return
    end
    
    amplitude_Vp = 2*convert_dBm_to_Vp(amplitude_in_dBm); % 2* because of idiosyncracy of AWG output channel - 1Vpp, not 2Vpp

    if amplitude_Vp < 0.01 && amplitude_in_dBm ~= -1000
        disp('AWG cannot output desired voltage accurately')
        return
    elseif amplitude_in_dBm == -1000
        amplitude_Vp = 0;
    end
    
    waveform_time = waveform_time_us* 1e-6;
    
    time_axis = 0 : 1/awg_clock : waveform_time - 1/awg_clock;

    if abs((awg_clock/1e6)*((time_axis(end)+ 1/awg_clock)*1e6 ) - floor((awg_clock/1e6)*((time_axis(end) + 1/awg_clock)*1e6 ))) > 1/awg_clock/10 && ...
        abs((awg_clock/1e6)*((time_axis(end)+ 1/awg_clock)*1e6 ) - ceil((awg_clock/1e6)*((time_axis(end) + 1/awg_clock)*1e6 ))) > 1/awg_clock/10  
        disp('check pulse length and clock freq')
        return
    end
    
    if abs(max(diff(time_axis) - mean(diff(time_axis)))) > 1e-19
        disp('time prob')
        return
    end
    
    waveform_data = amplitude_Vp*sin(2*pi*IF_waveform_freq*(time_axis) + phase*pi/180);
    marker_data = zeros(2, length(time_axis));
    marker_data(2, :) = marker_2_value;
end