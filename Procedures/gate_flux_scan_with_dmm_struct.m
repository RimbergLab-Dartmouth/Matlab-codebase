function[freq_measured, amp_measured, phase_measured, dc_bias_values]=...
    gate_flux_scan_with_dmm_struct(vna_handle,dmm_handle_1,dmm_handle_2,flux_start,flux_stop,flux_points...
    ,gate_start,gate_stop,gate_points,averaging,BW,electrical_delay,wait_time, vna_parameter_setter, dat_file_writer, file_number)   %
% tic

total_series_resistance = 11.2e3; % series resistance on flux line, for current conversion

% temp.center = 5.76e9;
% temp.span = 250e6;
% temp.vna_points = 1601;
% temp.vna_power = -65;

if ~exist('dat_file_writer', 'var')
    dat_file_writer = 0;
end

%%%% this will not reset any, number points, center, span settings. 
if ~exist('vna_parameter_setter', 'var')
    vna_parameter_setter = 0;
end

if ~exist('wait_time','var')
	wait_time=0;
end
if ~exist('file_number','var')
	file_name=['flux_scan_temp_'];
else
file_name=['flux_scan_' num2str(file_number) '_'];
end
% wait_time=0;
daq_handle=daq.createSession('ni');
fprintf(vna_handle,':calc1:par:coun 2');
vna_set_average(vna_handle,averaging,1);
vna_set_average(vna_handle,averaging,2);
vna_set_s_parameters(vna_handle,'s21',1,1);
vna_set_s_parameters(vna_handle,'s21',1,2);
vna_set_format(vna_handle,'mlog',1,1);
vna_set_format(vna_handle,'pph',1,2);
if vna_parameter_setter == 1 
    if ~exist('temp', 'var')
        temp.center = input('vna center in Hz');
        temp.span = input('vna span in Hz');
        temp.vna_points = input('vna number points');
        temp.vna_power = input('vna power in dBm');
    end
	vna_set_center_span(vna_handle,temp.center,temp.span,1);
    vna_set_sweep_points(vna_handle, temp.vna_points, 1)
    vna_set_power(vna_handle, temp.vna_power, 1)
end
clear temp
% vna_set_sweep_points(vna_handle,401,2);
number_points_chan_1=str2double(query(vna_handle,':sens1:swe:poin?'));
% number_points_chan_2=query(vna_handle,':sens2:swe:poin?');
vna_set_IF_BW(vna_handle,BW,1);
vna_set_electrical_delay(vna_handle,electrical_delay,1,2);


addAnalogOutputChannel(daq_handle,'Dev1','ao0','Voltage');
addAnalogOutputChannel(daq_handle,'Dev1','ao1','Voltage');
flux_step=(flux_stop-flux_start)/(flux_points-1);
gate_step=(gate_stop-gate_start)/(gate_points-1);
flux_number=ceil((flux_stop-flux_start)/flux_step)+1;
gate_number=ceil((gate_stop-gate_start)/gate_step)+1;
trace_1_amp_measured=ones(flux_number*gate_number*2,number_points_chan_1);
trace_2_amp_measured=ones(flux_number*gate_number*2,number_points_chan_1);
flux_gate_values=ones(flux_number*gate_number,2);
freq_measured = zeros(gate_number, flux_number, number_points_chan_1);
amp_measured = freq_measured;
phase_measured = freq_measured;
dc_bias_values = zeros(gate_number, flux_number, 2);

vna_turn_output_on(vna_handle);

gate=gate_start;
m_gate=1;
while gate<gate_stop+gate_step
    flux=flux_start;
    m_flux=1;
    tic
    while flux<flux_stop+flux_step
        outputSingleScan(daq_handle,[gate flux]);
        disp(['running gate = ' num2str(m_gate) ' of ' num2str(gate_number) ', flux = ' num2str(m_flux) ' of ' ...
            num2str(flux_number)])
        pause(3);
        vna_send_average_trigger(vna_handle);
%         vna_autoscale(vna_handle,1,1);
%         vna_autoscale(vna_handle,1,2);
        [xdata_1, ydata_1]=vna_get_data(vna_handle,1,1);
        [xdata_2, ydata_2]=vna_get_data(vna_handle,1,2);
        trace_1_amp_measured(2*flux_number*(m_gate-1)+2*m_flux-1,:)=xdata_1;
        trace_1_amp_measured(2*flux_number*(m_gate-1)+2*m_flux,:)=ydata_1;
        trace_2_amp_measured(2*flux_number*(m_gate-1)+2*m_flux-1,:)=xdata_2;
        trace_2_amp_measured(2*flux_number*(m_gate-1)+2*m_flux,:)=ydata_2;
        freq_measured(m_gate, m_flux, :) = xdata_1;
        amp_measured(m_gate, m_flux, :) = ydata_1;
        phase_measured(m_gate, m_flux, :) = ydata_2;
        flux_gate_values(flux_number*(m_gate-1)+m_flux,1)=dmm_get_voltage(dmm_handle_2)*1000;
        flux_gate_values(flux_number*(m_gate-1)+m_flux,2)=dmm_get_voltage(dmm_handle_1)*1e6/total_series_resistance;%in uA %2.17e3;%
        dc_bias_values(gate_number, flux_number, 1) = dmm_get_voltage(dmm_handle_2)*1000;
        dc_bias_values(gate_number, flux_number, 2) = dmm_get_voltage(dmm_handle_1)*1e6/total_series_resistance;%in uA %2.17e3;%
        pause(1);
        flux=flux+flux_step;
        m_flux=m_flux+1;
    end
%     flux_gate_values(flux_number*(m_gate-1)+m_flux-2,1)
    gate=gate+gate_step;
    if dat_file_writer == 1
        writematrix(trace_1_amp_measured,[file_name 'log_mag.dat']);
        writematrix(trace_2_amp_measured,[file_name 'pos_phase.dat']);
        writematrix(flux_gate_values,[file_name 'bias_values.dat']);
    end
    m_gate=m_gate+1;
    toc
    outputSingleScan(daq_handle,[0 0]);
    pause(wait_time);
end
outputSingleScan(daq_handle,[0 0]);
release(daq_handle);
% toc