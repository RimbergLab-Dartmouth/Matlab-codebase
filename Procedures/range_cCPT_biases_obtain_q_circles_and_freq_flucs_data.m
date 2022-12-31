if ~exist('bias_point', 'var')
    disp('enter directory where bias_point_struct.mat is saved')
   load_directory = uigetdir;
   load([load_directory '\bias_point_struct.mat'], 'bias_point')
   clear load_directory
end

if ~exist('gain_prof', 'var')
    disp('enter directory where gain_prof_struct.mat is saved')
   load_directory = uigetdir('enter directory where gain_prof_struct.mat is saved');
   load([load_directory '\gain_prof_struct.mat'], 'gain_prof')
   clear load_directory
end
%% input params
input_params.flux_start = -1; % units of \Phi_0
input_params.flux_stop = 0.1;
input_params.flux_number = 23;
input_params.ng_start = -.7; % units of number electrons
input_params.ng_stop = .7;
input_params.ng_number = 29;
input_params.flux_values = linspace(input_params.flux_start, input_params.flux_stop, input_params.flux_number);
input_params.ng_values = linspace(input_params.ng_start, input_params.ng_stop, input_params.ng_number);
input_params.constants.planck = 6.626e-34;
input_params.constants.boltzmann = 1.38e-23;
input_params.save_figures = 1;
input_params.figures_visible = 1;
input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
mkdir([cd '/d' input_params.file_name_time_stamp '_q_circles']);

%% vna params 
input_params.vna.rough_center = 5.76e9;
input_params.vna.rough_average_number = 35;
input_params.vna.rough_span = 250e6;
input_params.vna.rough_IF_BW = 10e3;
input_params.vna.rough_number_points = 1601;
input_params.vna.rough_electrical_delay = 62.6e-9; 
input_params.vna.rough_smoothing_aperture_amp = 1; % percent
input_params.vna.rough_smoothing_aperture_phase = 1.5; % percent

input_params.vna.zoom_average_number = 50;
input_params.vna.zoom_span = 20e6;
input_params.vna.zoom_IF_BW = 1e3;
input_params.vna.zoom_number_points = 201;
input_params.vna.zoom_electrical_delay = 62.6e-9; 
input_params.vna.zoom_smoothing_aperture_amp = 1; % percent
input_params.vna.zoom_smoothing_aperture_phase = 1.5; % percent

input_params.vna.power = -65;

%% sa params
input_params.sa.span = 10e3;
input_params.sa.number_points = 10001;
input_params.sa.average_number = 5;
input_params.sa.average_type = 'RMS';
input_params.sa.trace_type = 'average';
input_params.sa.RBW = 1;

%% sig gen params
input_params.sig_gen.model = 'n5183'; % n5183 or e8257c
input_params.sig_gen.power = -65;

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

%% initialize empty arrays
data.vna.rough_freq = zeros(input_params.flux_number, input_params.ng_number, ...
    input_params.vna.rough_number_points);
data.vna.rough_amp = data.vna.rough_freq;  
data.vna.rough_phase = data.vna.rough_freq;  
data.vna.freq_zoom = zeros(input_params.flux_number, input_params.ng_number, ...
    input_params.vna.zoom_number_points);
data.vna.amp_zoom = data.vna.freq_zoom;  
data.vna.phase_zoom = data.vna.freq_zoom;  
data.sa.freq = zeros(input_params.flux_number, input_params.ng_number, ...
    input_params.sa.number_points);
data.sa.amp = data.sa.freq;
data.bias_point_set.flux_voltage_desired = zeros(input_params.flux_number, input_params.ng_number);
data.bias_point_set.flux_voltage_measured = data.bias_point_set.flux_voltage_desired;
data.bias_point_set.gate_voltage_desired = zeros(input_params.flux_number, input_params.ng_number);
data.bias_point_set.gate_voltage_measured = data.bias_point_set.gate_voltage_desired;
data.bias_point_set.res_freq_expected = zeros(input_params.flux_number, input_params.ng_number);
data.bias_point_set.res_freq_error_measured = zeros(input_params.flux_number, input_params.ng_number);
data.vna.dc_bias = zeros(input_params.flux_number, input_params.ng_number, 2);
tic

%% data acquisition loop
for m_flux = 1 : input_params.flux_number
    connect_instruments
    for m_ng = 1 : input_params.ng_number
        disp(['running flux = ' num2str(m_flux) ' of ' num2str(input_params.flux_number) ', ng = ' ...
            num2str(m_ng) ' of ' num2str(input_params.ng_number)])
        switch_vna_measurement
        pause(1)
        %% set bias_point
        [temp_expected_bias_point_params_struct] = ...
            set_bias_point_using_offset_period_struct(input_params.ng_values(m_ng),input_params.flux_values(m_flux), bias_point, 0,1,vna);
        
        data.bias_point_set.flux_voltage_desired (m_flux, m_ng) = temp_expected_bias_point_params_struct.desired_flux_voltage;
        data.bias_point_set.gate_voltage_desired (m_flux, m_ng) = temp_expected_bias_point_params_struct.desired_gate_voltage;
        data.bias_point_set.res_freq_expected (m_flux, m_ng) = temp_expected_bias_point_params_struct.expected_freq;
        data.bias_point_set.res_freq_error_measured (m_flux, m_ng) = temp_expected_bias_point_params_struct.freq_error;        
        data.bias_point_set.flux_voltage_measured (m_flux, m_ng) = dmm_get_voltage(dmm_1);
        data.bias_point_set.gate_voltage_measured (m_flux, m_ng) = dmm_get_voltage(dmm_2);
        data.vna.dc_bias (m_flux, m_ng, 2) = data.bias_point_set.flux_voltage_measured (m_flux, m_ng);
        data.vna.dc_bias (m_flux, m_ng, 1) = data.bias_point_set.gate_voltage_measured (m_flux, m_ng);
        clear temp_expected_bias_point_params_struct
        %% set rough VNA 
        vna_set_center_span(vna, input_params.vna.rough_center, input_params.vna.rough_span, 1)
        vna_set_IF_BW(vna,input_params.vna.rough_IF_BW,1)
        vna_set_sweep_points(vna,input_params.vna.rough_number_points,1)
        vna_set_average(vna,input_params.vna.rough_average_number,1)
        vna_set_electrical_delay(vna, input_params.vna.rough_electrical_delay, 1, 2)
        vna_set_power(vna,input_params.vna.power,1)
        if isfield(input_params.vna, 'rough_smoothing_aperture_amp')
            vna_set_smoothing_aperture(vna, 1, 1, input_params.vna.rough_smoothing_aperture_amp)
            vna_turn_smoothing_on_off(vna, 1, 1, 'on')
        end
        if isfield(input_params.vna, 'rough_smoothing_aperture_phase')
            vna_set_smoothing_aperture(vna, 1, 1, input_params.vna.rough_smoothing_aperture_phase)
            vna_turn_smoothing_on_off(vna, 1, 2, 'on')
        end
        %% collect VNA rough data
        vna_turn_output_on(vna)
        vna_send_average_trigger(vna);
        [temp.rough.vna_freq, temp.rough.vna_amp] = vna_get_data(vna,1,1);
        [~, temp.rough.vna_phase]=vna_get_data(vna,1,2);
        
        temp.rough.sub_amp = temp.rough.vna_amp - gain_prof.amp;
        temp.rough.sub_phase = temp.rough.vna_amp - gain_prof.phase;
        
        %%%%%use phase to find resonance and zoom in %%%%%%%
%         phase_diff=diff(sub_phase);
%         [index_row,index_col]=max(abs(phase_diff));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%% use log mag to find resonance and zoom in %%%%%%%%%
        [~,temp.rough.index_col] = min(temp.rough.sub_amp);
        data.rough_resonance_freq (m_flux, m_ng) = temp.rough.vna_freq(temp.rough.index_col);
        vna_set_marker_freq(vna, 1,data.rough_resonance_freq (m_flux, m_ng),1);
        %% set VNA zoom data
        vna_set_center_span(vna, data.rough_resonance_freq (m_flux, m_ng), input_params.vna.zoom_span, 1)
        vna_set_IF_BW(vna,input_params.vna.zoom_IF_BW,1)
        vna_set_sweep_points(vna,input_params.vna.zoom_number_points,1)
        vna_set_average(vna,input_params.vna.zoom_average_number,1)
        vna_set_electrical_delay(vna, input_params.vna.zoom_electrical_delay, 1, 2)
        vna_set_power(vna,input_params.vna.power,1)
        if isfield(input_params.vna, 'zoom_smoothing_aperture_amp')
            vna_set_smoothing_aperture(vna, 1, 1, input_params.vna.zoom_smoothing_aperture_amp)
            vna_turn_smoothing_on_off(vna, 1, 1, 'on')
        end
        if isfield(input_params.vna, 'zoom_smoothing_aperture_phase')
            vna_set_smoothing_aperture(vna, 1, 1, input_params.vna.zoom_smoothing_aperture_phase)
            vna_turn_smoothing_on_off(vna, 1, 2, 'on')
        end
        
        %% collect VNA zoom data
        vna_send_average_trigger(vna);
        [temp.zoom.vna_freq, temp.zoom.vna_amp] = vna_get_data(vna,1,1);
        [~, temp.zoom.vna_phase]=vna_get_data(vna,1,2);
        
        %% transfer VNA data to permanent array
        data.vna.rough_freq (m_flux, m_ng, :) = temp.rough.vna_freq;
        data.vna.rough_amp (m_flux, m_ng, :)= temp.rough.vna_amp;
        data.vna.rough_phase (m_flux, m_ng, :)= temp.rough.vna_phase;
        data.vna.freq_zoom (m_flux, m_ng, :)= temp.zoom.vna_freq;
        data.vna.amp_zoom (m_flux, m_ng, :)= temp.zoom.vna_amp;
        data.vna.phase_zoom (m_flux, m_ng, :) = temp.zoom.vna_phase;
        
        %% switch to SA and sig gen line, perform measurement
%             disp('switch to SA')
        switch_sig_gen_sa_measurement(keysight_sg)
        n9000_set_center_span(sa, data.rough_resonance_freq (m_flux, m_ng),input_params.sa.span)
        
        if strcmp(input_params.sig_gen.model, 'n5183')
            n5183b_set_frequency(keysight_sg, data.rough_resonance_freq (m_flux, m_ng))
            n5183b_set_amplitude(keysight_sg, input_params.sig_gen.power)
            n5183b_toggle_output(keysight_sg, 'on')
        elseif strcmp(input_params.sig_gen.model, 'e8257c')
            e8257c_set_frequency(e8257c_sig_gen, data.rough_resonance_freq (m_flux, m_ng))
            e8257c_set_amplitude(e8257c_sig_gen, input_params.sig_gen.power)
            e8257c_toggle_output(e8257c_sig_gen, 'off')            
        end
        pause(1)

        [temp.sa.freq, temp.sa.amp] = n9000_get_freq_and_amp(sa);
        if strcmp(input_params.sig_gen.model, 'n5183')
            n5183b_toggle_output(keysight_sg, 'off')
        elseif strcmp(input_params.sig_gen.model, 'e8257c')
            e8257c_toggle_output(e8257c_sig_gen, 'off')
        end
        [temp.sa.freq_carrier_off, temp.sa.amp_carrier_off] = n9000_get_freq_and_amp(sa);
        %% transfer SA data to permanent array
        data.sa.freq (m_flux, m_ng, :) = temp.sa.freq;
        data.sa.amp (m_flux, m_ng, :) = temp.sa.amp;
%         data.sa.freq_carrier_off (m_flux, m_ng, :) = temp.sa.freq_carrier_off;
%%%% not saving carrier off freq to save on memory 
        data.sa.amp_carrier_off (m_flux, m_ng, :) = temp.sa.amp_carrier_off;
        elapsed_time = toc;
        data.data_point_time(m_flux, m_ng) = elapsed_time;
        disp(['Elapsed time since start of run : ' num2str(floor(elapsed_time/3600)) 'hrs, ' num2str(floor(mod(elapsed_time, 3600)/60)) 'mins, ' ...
            num2str(mod(mod(elapsed_time, 3600),60)) 'seconds'])
        clear temp elapsed_time
    end
    clear_instruments
    clear m_ng m_flux
    save([cd '/d' input_params.file_name_time_stamp '_q_circles/q_circle_and_freq_flucs_data.mat'])
end
switch_vna_measurement