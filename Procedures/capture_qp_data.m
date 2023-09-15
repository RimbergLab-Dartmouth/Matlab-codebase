%% input params
input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
mkdir([cd '/d' input_params.file_name_time_stamp '_qp_traces']);
input_params.vna.power = -65;
input_params.vna.average_number = 50;
input_params.vna.IF_BW = 10e3;
input_params.vna.number_points = 1601; %initially 1601
input_params.vna.center = 5.76e9;
input_params.vna.span = 250e6;
input_params.vna.electrical_delay = 62.6e-9; 
input_params.flux_start_phi_ext = 0;   % phi_ext values
input_params.flux_stop_phi_ext = 0.1;
input_params.flux_points = 1;
input_params.gate_start_ng = 0.65;  % ng values 
input_params.gate_stop_ng = 0.79;
input_params.gate_points = 21;
input_params.fine_gain_profile_exclude_span = 15e6; % span around resonance to omit in extracting gain
input_params.plot_display = 1;
input_params.num_to_plot = input_params.gate_points;

%% execute function
%%%% load bias point struct if it doesn't exist
if ~exist('bias_point', 'var')
    disp('enter directory where bias_point_struct.mat is saved')
   load_directory = uigetdir;
   load([load_directory '\bias_point_struct.mat'], 'bias_point')
   clear load_directory
end
%%%%% load gain profile if it doesn't exist
if ~exist('gain_prof', 'var')
   load_directory = uigetdir('enter directory where gain_prof_struct.mat is saved');
   load([load_directory '\gain_prof_struct.mat'], 'gain_prof')
   clear load_directory
end

%%% convert ng values to voltage
input_params.gate_start_voltage_struct = set_bias_point_using_offset_period_struct(input_params.gate_start_ng, 0, bias_point, 0, 0, vna);
input_params.gate_stop_voltage_struct = set_bias_point_using_offset_period_struct(input_params.gate_stop_ng, 0, bias_point, 0, 0, vna);
input_params.flux_start_voltage_struct = set_bias_point_using_offset_period_struct(0, input_params.flux_start_phi_ext, bias_point, 0, 0, vna);
input_params.flux_stop_voltage_struct = set_bias_point_using_offset_period_struct(0, input_params.flux_stop_phi_ext, bias_point, 0, 0, vna);

input_params.flux_start_voltage = input_params.flux_start_voltage_struct.desired_flux_voltage;
input_params.flux_stop_voltage = input_params.flux_stop_voltage_struct.desired_flux_voltage;
input_params.gate_start_voltage = input_params.gate_start_voltage_struct.desired_gate_voltage;
input_params.gate_stop_voltage = input_params.gate_stop_voltage_struct.desired_gate_voltage;

switch_vna_measurement
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
[freq_measured, amp_measured, phase_measured, dc_bias_values]=gate_flux_scan_with_dmm_struct(vna,dmm_2,dmm_1,input_params.flux_start_voltage,input_params.flux_stop_voltage,input_params.flux_points,...
input_params.gate_start_voltage,input_params.gate_stop_voltage,input_params.gate_points,input_params.vna.average_number,input_params.vna.IF_BW,input_params.vna.electrical_delay,0, 0);

vna_turn_output_off(vna)
clear_instruments
save([cd '/d' input_params.file_name_time_stamp '_qp_traces/flux_scan_data.mat'])
data.freq = squeeze(freq_measured);
data.amp = squeeze(amp_measured);
data.phase = squeeze(phase_measured);

clearvars -except input_params data gain_prof
save([cd '/d' input_params.file_name_time_stamp '_qp_traces/qp_data.mat'])
colors = parula(input_params.num_to_plot);
%%
if input_params.plot_display == 1
        gain_prof_freq_data = gain_prof.freq;
        gain_prof_amp = gain_prof.amp;
        gain_prof_phase = gain_prof.phase;
        disp('plotting')
        figure
        subplot(2,1,1)
        hold on
        min(input_params.num_to_plot, size(data.amp, 1))
        for i = 1: min(input_params.num_to_plot, size(data.amp, 1))
            data.subtracted.amp(i, :) = squeeze(data.amp(i, :) - gain_prof_amp);
            data.subtracted.phase(i, :) = squeeze(data.phase(i, :) - gain_prof_phase);
            plot(data.freq(i, :),data.subtracted.amp(i,:), 'color', colors(i, :))
        end
        c = colorbar;
        c.Ticks = linspace(0, 1, 10);
        c.TickLabels = round(linspace(input_params.gate_start_ng, input_params.gate_stop_ng, 10), 2);
        hL = ylabel(c,'$n_g$', 'interpreter', 'latex');     
        subplot(2,1,2)
        hold on
        for i = 1: min(input_params.num_to_plot, size(data.amp, 1))
            plot(data.freq(i, :),data.subtracted.phase(i,:), 'color', colors(i, :))
        end
end
    
saveas(gcf,[cd '/d' input_params.file_name_time_stamp '_qp_traces/qp_traces.fig'])
saveas(gcf,[cd '/d' input_params.file_name_time_stamp '_qp_traces/qp_traces.png'])
