run_params.file_name = 'gain_added_noise_TWPA_6656M_-2p24';
input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
input_params.file_directory = [cd '/d' input_params.file_name_time_stamp run_params.file_name];
mkdir(input_params.file_directory);
if ~exist('bias_point', 'var')
    disp('enter directory where bias_point_struct.mat is saved')
   load_directory = uigetdir;
   load([load_directory '\bias_point_struct.mat'], 'bias_point')
   clear load_directory
end
%% input params
input_params.flux_value = 0.5;
input_params.ng_value = 0;
input_params.twpa_pump.pump_on_off = 'on';
input_params.twpa_pump.freq_start = 6.656e9;
input_params.twpa_pump.freq_stop = 6.656e9;
input_params.twpa_pump.freq_number = 1;
input_params.twpa_pump.power_start = -2.24; % this is power on the actual sig gen itself, assumed to be the HP83711B
input_params.twpa_pump.power_stop = -2.24; 
input_params.twpa_pump.power_number = 1; 
input_params.twpa_pump.freqs = linspace(input_params.twpa_pump.freq_start, input_params.twpa_pump.freq_stop, input_params.twpa_pump.freq_number);
input_params.twpa_pump.powers = linspace(input_params.twpa_pump.power_start, input_params.twpa_pump.power_stop, input_params.twpa_pump.power_number);
% input_params.center_freq = [5.7e9; 5.75e9; 5.775e9; 5.8e9];
input_params.center_freq = [5.7e9; 5.72e9; 5.74e9; 5.76e9; 5.78e9; 5.8e9];
input_params.center_freq_number = length(input_params.center_freq);
input_params.input_attenuation = 83.1; % includes input cable attenuation
input_params.constants.planck = 6.626e-34;
input_params.constants.boltzmann = 1.38e-23;
input_params.save_figures = 1;
input_params.figures_visible = 1;

%% vna params 
input_params.vna.average_number = 35;
input_params.vna.span = 250e6;
input_params.vna.IF_BW = 10e3;
input_params.vna.number_points = 1601;
input_params.vna.electrical_delay = 62.6e-9; 
input_params.vna.power = -65;
input_params.vna.smoothing_aperture_amp = 1; % percent
input_params.vna.smoothing_aperture_phase = 1.5; % percent
%% sa params
input_params.sa.span = 1e3;
input_params.sa.number_points = 1001;
input_params.sa.average_number = 10;
input_params.sa.average_type = 'RMS';
input_params.sa.trace_type = 'average';
input_params.sa.RBW = 1;

%% set VNA 
vna_set_IF_BW(vna,input_params.vna.IF_BW,1)
vna_set_sweep_points(vna,input_params.vna.number_points,1)
vna_set_average(vna,input_params.vna.average_number,1)
vna_set_power(vna,input_params.vna.power,1)
if isfield(input_params.vna, 'smoothing_aperture_amp')
    vna_set_smoothing_aperture(vna, 1, 1, input_params.vna.smoothing_aperture_amp)
    vna_turn_smoothing_on_off(vna, 1, 1, 'on')
end
if isfield(input_params.vna, 'smoothing_aperture_phase')
    vna_set_smoothing_aperture(vna, 1, 1, input_params.vna.smoothing_aperture_phase)
    vna_turn_smoothing_on_off(vna, 1, 2, 'on')
end

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
%% ensure other sig gens are all off
n5183b_toggle_modulation(keysight_sg, 'off')
n5183b_toggle_pulse_mod(keysight_sg, 'off')
n5183b_toggle_output(keysight_sg, 'off')
e8257c_toggle_output(e8257c_sig_gen, 'off')

%% set bias_point
    [data.expected_bias_point_params_struct] = ...
set_bias_point_using_offset_period_struct(input_params.ng_value,input_params.flux_value, bias_point, 0,1,vna);

%% initialize empty arrays
data.vna.freq = zeros(input_params.twpa_pump.freq_number, input_params.twpa_pump.power_number, ...
    input_params.center_freq_number, input_params.vna.number_points);
data.vna.amp = data.vna.freq;  
data.vna.phase = data.vna.freq;  
data.sa.freq = zeros(input_params.twpa_pump.freq_number, input_params.twpa_pump.power_number, ...
    input_params.center_freq_number, input_params.sa.number_points);
data.sa.amp = data.sa.freq;
data.vna.analyzed_freq = zeros(input_params.twpa_pump.freq_number, input_params.twpa_pump.power_number, input_params.center_freq_number);
data.vna.analyzed_amp = zeros(input_params.twpa_pump.freq_number, input_params.twpa_pump.power_number, input_params.center_freq_number);
data.sa.analyzed_freq = zeros(input_params.twpa_pump.freq_number, input_params.twpa_pump.power_number, input_params.center_freq_number);
data.sa.analyzed_amp = data.sa.analyzed_freq; 
analysis.gain = data.sa.analyzed_freq;
analysis.added_noise_watts = data.sa.analyzed_freq;
analysis.added_noise_temp = data.sa.analyzed_freq;
analysis.added_noise_photons = data.sa.analyzed_freq;
tic

%% data acquisition loop
for m_twpa_freq = 1 : input_params.twpa_pump.freq_number
    connect_instruments
    for m_twpa_power = 1 : input_params.twpa_pump.power_number
        if strcmp(input_params.twpa_pump.pump_on_off, 'on')
            set_83711B(hp_high_freq_sg, input_params.twpa_pump.freqs(m_twpa_freq), input_params.twpa_pump.powers(m_twpa_power), 1);
        elseif strcmp(input_params.twpa_pump.pump_on_off, 'off')
            set_83711B(hp_high_freq_sg, input_params.twpa_pump.freqs(m_twpa_freq), input_params.twpa_pump.powers(m_twpa_power), 0);
        end
        for m_center_freq = 1 : input_params.center_freq_number
            disp(['running pump freq = ' num2str(m_twpa_freq) ' of ' num2str(input_params.twpa_pump.freq_number) ', pump power = ' ...
                num2str(m_twpa_power) ' of ' num2str(input_params.twpa_pump.power_number) ', center freq = ' ...
                num2str(m_center_freq) ' of ' num2str(input_params.center_freq_number)])
            
            switch_vna_measurement
%             disp('switch to VNA')
            pause(1)
            vna_set_center_span(vna,input_params.center_freq(m_center_freq),input_params.vna.span,1);
            vna_turn_output_on(vna)
            vna_send_average_trigger(vna);
            [vna_freq, vna_amp] = vna_get_data(vna,1,1);
            [~, vna_phase]=vna_get_data(vna,1,2);
            vna_analyzed_freq = vna_freq((input_params.vna.number_points - 1)/2 + 1);
            vna_analyzed_amp = vna_amp((input_params.vna.number_points - 1)/2 + 1);
            gain = vna_analyzed_amp + input_params.input_attenuation;

%             disp('switch to SA')
            switch_sig_gen_sa_measurement(keysight_sg)
            n9000_set_center_span(sa, input_params.center_freq(m_center_freq),input_params.sa.span)
            pause(1)

            [sa_freq, sa_amp]=n9000_get_freq_and_amp(sa);

            sa_carrier_amp = mean(sa_amp);  % mean around the 1kHz span is a better indication of the noise compared to the actual random value at the center freq

            added_noise = sa_carrier_amp - gain;
            [~, added_noise_watts] = convert_dBm_to_Vp(added_noise);
            added_noise_temp = added_noise_watts/input_params.constants.boltzmann;
            added_noise_photons = added_noise_watts/input_params.constants.planck/vna_analyzed_freq;

            data.vna.freq(m_twpa_freq, m_twpa_power, m_center_freq, :) = vna_freq;
            data.vna.amp(m_twpa_freq, m_twpa_power, m_center_freq, :) = vna_amp;
            data.vna.phase(m_twpa_freq, m_twpa_power, m_center_freq, :) = vna_phase;
            data.vna.analyzed_freq(m_twpa_freq, m_twpa_power, m_center_freq) = vna_analyzed_freq;
            data.vna.analyzed_amp(m_twpa_freq, m_twpa_power, m_center_freq) = vna_analyzed_amp;
            data.sa.freq(m_twpa_freq, m_twpa_power, m_center_freq, :) = sa_freq;
            data.sa.amp(m_twpa_freq, m_twpa_power, m_center_freq, :) = sa_amp;
            data.sa.analyzed_freq(m_twpa_freq, m_twpa_power, m_center_freq) = sa_freq((input_params.sa.number_points - 1)/2 + 1);
            data.sa.analyzed_amp(m_twpa_freq, m_twpa_power, m_center_freq) = sa_amp((input_params.sa.number_points - 1)/2 + 1);
            analysis.gain(m_twpa_freq, m_twpa_power, m_center_freq) = gain;
            analysis.added_noise_watts(m_twpa_freq, m_twpa_power, m_center_freq) = added_noise_watts;
            analysis.added_noise_temp(m_twpa_freq, m_twpa_power, m_center_freq) = added_noise_temp;
            analysis.added_noise_photons(m_twpa_freq, m_twpa_power, m_center_freq) = added_noise_photons;
            elapsed_time = toc;
            data.data_point_time(m_twpa_freq, m_twpa_power, m_center_freq) = elapsed_time;
            disp(['Elapsed time since start of run : ' num2str(floor(elapsed_time/3600)) 'hrs, ' num2str(floor(mod(elapsed_time, 3600)/60)) 'mins, ' ...
                num2str(mod(mod(elapsed_time, 3600),60)) 'seconds'])
            clear vna_freq ...
                  vna_amp ...
                  vna_phase ...
                  vna_analyzed_freq ...
                  vna_analyzed_amp ...
                  sa_freq ...
                  sa_amp ...
                  gain ...
                  added_noise_watts ...
                  added_noise_temp ...
                  added_noise_photons ...
                  elapsed_time
        end
    end
    clear_instruments
    analysis.added_noise_watts_average = mean(analysis.added_noise_watts, 3);
    analysis.added_noise_temp_average = mean(analysis.added_noise_temp, 3);
    analysis.added_noise_photons_average = mean(analysis.added_noise_photons, 3);
    analysis.gain_average = mean(analysis.gain, 3);
    [analysis.min_added_noise_photons_average,idx]=min(analysis.added_noise_photons_average(:));
    [pump_freq_index,pump_power_index]=ind2sub(size(analysis.added_noise_photons_average),idx);
    analysis.min_added_noise_twpa_pump_freq = input_params.twpa_pump.freqs(pump_freq_index);
    analysis.min_added_noise_twpa_pump_power = input_params.twpa_pump.powers(pump_power_index);
    clear idx ...
          pump_freq_index ...
          pump_power_index
    save([input_params.file_directory '/gain_added_noise_data.mat'])
end
switch_vna_measurement

%% plotting
if input_params.figures_visible == 1
    added_noise_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
else
    added_noise_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
end
surf(input_params.twpa_pump.freqs/1e9, input_params.twpa_pump.powers, analysis.added_noise_photons_average')
colorbar
view(0,90)
caxis([1 5])
xlabel('Pump Freq (GHz)', 'interpreter', 'latex')
ylabel('Pump power (dBm)', 'interpreter', 'latex')
title('Average added noise photons')
if input_params.save_figures == 1
    saveas(added_noise_figure, [input_params.file_directory '/added_noise_vs_twpa_pump.fig'])
    saveas(added_noise_figure, [input_params.file_directory '/added_noise_vs_twpa_pump.png'])
end

if input_params.figures_visible == 1
    gain_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
else
    gain_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
end
surf(input_params.twpa_pump.freqs/1e9, input_params.twpa_pump.powers, analysis.gain_average')
colorbar
view(0,90)
caxis([75 95])
xlabel('Pump Freq (GHz)', 'interpreter', 'latex')
ylabel('Pump power (dBm)', 'interpreter', 'latex')
title('Average gain')
if input_params.save_figures == 1
    saveas(gain_figure, [input_params.file_directory '/gain_vs_twpa_pump.fig'])
    saveas(gain_figure, [input_params.file_directory '/gain_vs_twpa_pump.png'])
end