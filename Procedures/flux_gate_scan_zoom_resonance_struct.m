 function[freq_measured, amp_measured, phase_measured, freq_zoomed, amp_zoomed, phase_zoomed, dc_bias_values]=...
    flux_gate_scan_zoom_resonance_struct(vna_handle,dmm_handle_1,dmm_handle_2,flux_start,flux_stop,flux_step...
    ,gate_start,gate_stop,gate_step, gain_prof_struct, vna_params_struct, file_number, dat_file_save_param ,wait_time)
tic

flux_series_resistor = 11.2e3;

if ~exist('wait_time','var')
	wait_time=0;
end

if ~exist('dat_file_save_param', 'var')
    dat_file_save_param = 0;
end

if ~exist('vna_params_struct', 'var')
    vna_params_struct.center = 5.76e9;
    vna_params_struct.span = 250e6;
    vna_params_struct.vna_points = 1601;
    vna_params_struct.electrical_delay = 62.6e-9;
    vna_params_struct.zoom_span = 20e6;
    vna_params_struct.vna_points_zoom = 201;
    vna_params_struct.IF_BW = 10e3;
    vna_params_struct.IF_BW_zoom = 1e3;
    vna_params_struct.average_number = 35;
    vna_params_struct.average_number_zoom = 50;
    vna_params_struct.power = -65;
end

%%%%%% parameters %%%%%%%%
if ~exist('file_number','var')
	file_name=['gate_scan_temp_'];
else
file_name=['gate_scan_' num2str(file_number) '_'];
end
%%%%%%%%%%%%%%%%%%%%%%%

daq_handle=daq.createSession('ni');
fprintf(vna_handle,':calc1:par:coun 2');
vna_set_s_parameters(vna_handle,'s21',1,1);  
vna_set_s_parameters(vna_handle,'s21',1,2);
vna_set_format(vna_handle,'mlog',1,1);
vna_set_format(vna_handle,'pph',1,2);
vna_set_electrical_delay(vna_handle,vna_params_struct.electrical_delay,1,2);
% number_points_chan_1=str2double(query(vna_handle,':sens1:swe:poin?'));
% number_points_chan_2=query(vna_handle,':sens2:swe:poin?');

addAnalogOutputChannel(daq_handle,'Dev1','ao0','Voltage');
addAnalogOutputChannel(daq_handle,'Dev1','ao1','Voltage');
addAnalogInputChannel(daq_handle,'Dev1','ai1','Voltage');
addAnalogInputChannel(daq_handle,'Dev1','ai2','Voltage');
flux_number=ceil((flux_stop-flux_start)/flux_step);
gate_number=ceil((gate_stop-gate_start)/gate_step);
trace_1_amp_measured=ones(flux_number*gate_number*2,vna_params_struct.number_points);
trace_2_amp_measured=ones(flux_number*gate_number*2,vna_params_struct.number_points);
trace_1_amp_fine=ones(flux_number*gate_number*2,vna_params_struct.number_points_zoom);
trace_2_amp_fine=ones(flux_number*gate_number*2,vna_params_struct.number_points_zoom);
flux_gate_values=ones(flux_number*gate_number,2);

freq_measured = zeros(flux_number, gate_number, vna_params_struct.number_points);
amp_measured = freq_measured;
phase_measured = freq_measured;
freq_zoomed= zeros(flux_number, gate_number, vna_params_struct.number_points_zoom);
amp_zoomed = freq_zoomed;
phase_zoomed = freq_zoomed; 
dc_bias_values = zeros(flux_number, gate_number, 2);

vna_set_power(vna_handle, vna_params_struct.power, 1)
vna_turn_output_on(vna_handle);

flux=flux_start;
for m_flux = 1 : flux_number
    gate=gate_start;
    for m_gate=1 : gate_number
        disp(['running flux = ' num2str(m_flux) ' of ' num2str(flux_number) ', gate = ' num2str(m_gate) ' of ' num2str(gate_number)])
        vna_set_center_span(vna_handle,vna_params_struct.center,vna_params_struct.span,1);
        vna_set_sweep_points(vna_handle,vna_params_struct.number_points,1);
        vna_set_IF_BW(vna_handle,vna_params_struct.IF_BW,1);
        vna_set_average(vna_handle,vna_params_struct.average_number,1);
        outputSingleScan(daq_handle,[gate flux]);
        pause(3);
        vna_send_average_trigger(vna_handle);
        vna_autoscale(vna_handle,1,1);
        vna_autoscale(vna_handle,1,2);
        [xdata_1, ydata_1] = vna_get_data(vna_handle,1,1);
        [xdata_2, ydata_2] = vna_get_data(vna_handle,1,2);
        trace_1_amp_measured(2*gate_number*(m_flux-1)+2*m_gate-1,:) = xdata_1;
        trace_1_amp_measured(2*gate_number*(m_flux-1)+2*m_gate,:) = ydata_1;
        trace_2_amp_measured(2*gate_number*(m_flux-1)+2*m_gate-1,:) = xdata_2;
        trace_2_amp_measured(2*gate_number*(m_flux-1)+2*m_gate,:) = ydata_2;
        flux_gate_values(gate_number*(m_flux-1)+m_gate,1) = dmm_get_voltage(dmm_handle_2)*1000; % in mV
        flux_gate_values(gate_number*(m_flux-1)+m_gate,2) = dmm_get_voltage(dmm_handle_1)*1e6/11.2e3; % in uA
        dc_bias_values(m_flux, m_gate, 1) = dmm_get_voltage(dmm_handle_2)*1000; % in mV
        dc_bias_values(m_flux, m_gate, 2) = dmm_get_voltage(dmm_handle_1)*1e6/flux_series_resistor; % in uA
        pause(1);
        sub_ydata_1 = ydata_1-gain_prof_struct.amp;
        sub_ydata_2 = ydata_2-gain_prof_struct.phase;
        
        %%%%%use phase to find resonance and zoom in %%%%%%%
%         phase_diff=diff(sub_ydata_2);
%         [index_row,index_col]=max(abs(phase_diff));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%% use log mag to find resonance and zoom in %%%%%%%%%
        [~,index_col] = min(sub_ydata_1);
        resonance_freq=xdata_1(index_col);
        vna_set_marker_freq(vna_handle,1,resonance_freq,1);
%         pause(2);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        vna_set_center_span(vna_handle,resonance_freq,vna_params_struct.span_zoom,1);
        vna_set_sweep_points(vna_handle,vna_params_struct.number_points_zoom,1);
        vna_set_IF_BW(vna_handle,vna_params_struct.IF_BW_zoom,1);
        vna_set_average(vna_handle,vna_params_struct.average_number_zoom,1);
        vna_send_average_trigger(vna_handle);
        vna_autoscale(vna_handle,1,1);
        vna_autoscale(vna_handle,1,2);
        [xdata_1_fine, ydata_1_fine]=vna_get_data(vna_handle,1,1);
        [xdata_2_fine, ydata_2_fine]=vna_get_data(vna_handle,1,2);
        trace_1_amp_fine(2*gate_number*(m_flux-1)+2*m_gate-1,:)=xdata_1_fine;
        trace_1_amp_fine(2*gate_number*(m_flux-1)+2*m_gate,:)=ydata_1_fine;
        trace_2_amp_fine(2*gate_number*(m_flux-1)+2*m_gate-1,:)=xdata_2_fine;
        trace_2_amp_fine(2*gate_number*(m_flux-1)+2*m_gate,:)=ydata_2_fine;
        freq_measured(m_flux, m_gate, :) = xdata_1;
        amp_measured(m_flux, m_gate, :) = ydata_1;
        phase_measured(m_flux, m_gate, :) = ydata_2;
        freq_zoomed(m_flux, m_gate, :) = xdata_1_fine;
        amp_zoomed(m_flux, m_gate, :) = ydata_1_fine;
        phase_zoomed(m_flux, m_gate, :) = ydata_2_fine; 
        
        gate=gate+gate_step;
        m_gate=m_gate+1;
    end
    flux=flux+flux_step;
    if dat_file_save_param == 1
        writematrix(trace_1_amp_measured,[file_name 'log_mag.dat']);
        writematrix(trace_2_amp_measured,[file_name 'pos_phase.dat']);
        writematrix(flux_gate_values,[file_name 'bias_values.dat']);
        writematrix(trace_1_amp_fine,[file_name 'log_mag_zoom.dat']);
        writematrix(trace_2_amp_fine,[file_name 'pos_phase_zoom.dat']);
    end
    
    pause(wait_time);
    m_flux = m_flux+1;
    elapsed_time = toc;
    disp(['Elapsed time since start of run : ' num2str(floor(elapsed_time/3600)) 'hrs, ' num2str(floor(mod(elapsed_time, 3600)/60)) 'mins, ' ...
                num2str(mod(mod(elapsed_time, 3600),60)) 'seconds'])
end
vna_turn_output_off(vna_handle)
vna_set_trigger_source(vna_handle,'INT');
release(daq_handle);
toc