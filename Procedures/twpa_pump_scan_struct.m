function[trace_1_amp_measured,trace_2_amp_measured, flux_gate_values,pump_values]=...
    twpa_pump_scan(vna_handle,sg_handle,freq_start,freq_stop,freq_step...
    ,power_start,power_stop,power_step)
tic
daq_handle=daq.createSession('ni');
fprintf(vna_handle,':calc1:par:coun 2');
vna_set_average(vna_handle,80,1);
% vna_set_average(vna_handle,40,2);
vna_set_s_parameters(vna_handle,'s21',1,1);
vna_set_s_parameters(vna_handle,'s21',1,2);
vna_set_format(vna_handle,'mlog',1,1);
vna_set_format(vna_handle,'uph',1,2);
% vna_set_center_span(vna_handle,5.6765e9,20e6,1);
% vna_set_center_span(vna_handle,5.6829e9,30e6,2);
vna_set_sweep_points(vna_handle,401,1);
% vna_set_sweep_points(vna_handle,401,2);
vna_set_electrical_delay(vna_handle,50.5e-9,1,2);
number_points_chan_1=str2double(query(vna_handle,':sens1:swe:poin?'));
% number_points_chan_2=query(vna_handle,':sens2:swe:poin?');

% addAnalogOutputChannel(daq_handle,'Dev1','ao0','Voltage');
% addAnalogOutputChannel(daq_handle,'Dev1','ao1','Voltage');
addAnalogInputChannel(daq_handle,'Dev1','ai1','Voltage');
addAnalogInputChannel(daq_handle,'Dev1','ai2','Voltage');
freq_number=ceil((freq_stop-freq_start)/freq_step);
power_number=ceil((power_stop-power_start)/power_step);
trace_1_amp_measured=ones(freq_number*power_number*2,number_points_chan_1);
trace_2_amp_measured=ones(freq_number*power_number*2,number_points_chan_1);
flux_gate_values=ones(freq_number*power_number,2);
vna_turn_output_on(vna_handle);
pump_values=ones(freq_number*power_number,2);


freq=freq_start;
i=1;
while freq<freq_stop+freq_step
    pump_power=power_start;
    j=1;
    while pump_power<power_stop+power_step
        e8257c_set_frequency(sg_handle,freq);
        e8257c_set_amplitude(sg_handle,pump_power);
        e8257c_toggle_output(sg_handle,'on');
        pause(3);
        vna_send_average_trigger(vna_handle);
        vna_marker_search(vna_handle,1,'min','on',1,1);
        vna_autoscale(vna_handle,1,1);
        vna_autoscale(vna_handle,1,2);
        [xdata_1 ydata_1]=vna_get_data(vna_handle,1,1);
        [xdata_2 ydata_2]=vna_get_data(vna_handle,1,2);
        trace_1_amp_measured(2*power_number*(i-1)+2*j-1,:)=xdata_1;
        trace_1_amp_measured(2*power_number*(i-1)+2*j,:)=ydata_1;
        trace_2_amp_measured(2*power_number*(i-1)+2*j-1,:)=xdata_2;
        trace_2_amp_measured(2*power_number*(i-1)+2*j,:)=ydata_2;
        flux_gate_values(power_number*(i-1)+j,:)=daq_handle.inputSingleScan';
        flux_gate_values(power_number*(i-1)+j,1)=flux_gate_values(power_number*(i-1)+j,1)*1000;
        pump_values(power_number*(i-1)+j,1)=freq;
        pump_values(power_number*(i-1)+j,2)=pump_power;
        e8257c_toggle_output(sg_handle,'off');
        pause(1);
        pump_power=pump_power+power_step;
        j=j+1;
    end
    freq=freq+freq_step;
    i=i+1;
end
release(daq_handle);
toc