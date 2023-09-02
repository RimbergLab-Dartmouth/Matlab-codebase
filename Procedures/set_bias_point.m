function[] = set_bias_point(desired_gate_point,desired_flux_point)
    %% fetch instrument from base
    disp('connect_instument and load bias_point')
    dmm_1 = evalin('base', 'dmm_1');
    dmm_2 = evalin('base', 'dmm_2');
    vna = evalin('base', 'vna');
    bias_finder_struct = evalin('base', 'bias_point');
    

    %% calculate desired voltage using bias_point information
    desired_flux_voltage = bias_finder_struct.flux_zero_voltage + (desired_flux_point * bias_finder_struct.flux_period);
    desired_gate_voltage = (bias_finder_struct.gate_offset + desired_gate_point * bias_finder_struct.gate_period/2);
    
    %% expected resonance freq calculation
    [~, theory_freq_shift] = res_freq_expected_for_Jules_sample(desired_gate_point, desired_flux_point);
    expected_freq = theory_freq_shift + bias_finder_struct.flux_center_freq_mean;
    
    %% set DC voltages for the gate and flux lines and obtain voltage reading
    daq_handle=daq.createSession('ni');
    addAnalogOutputChannel(daq_handle,'Dev1','ao0','Voltage');
    addAnalogOutputChannel(daq_handle,'Dev1','ao1','Voltage');
    outputSingleScan(daq_handle,[desired_gate_voltage desired_flux_voltage]);
    pause(3);
    flux_voltage_status = dmm_get_voltage(dmm_2);
    gate_voltage_status = dmm_get_voltage(dmm_1);
    fprintf('desired flux voltage is: %.4g mV, actual flux voltage is: %.4gmV \n',desired_flux_voltage*1e3, flux_voltage_status*1e3);
    fprintf('desired gate voltage is: %.4g mV, actual gate voltage is: %.4gmV \n',desired_gate_voltage*10, gate_voltage_status*1e3);
    
    %% set vna to look for the resonance and output actual
    vna_set_power(vna, -65)
    vna_set_center_span(vna,expected_freq,25e6,1);
    vna_set_sweep_points(vna,1601,1);
    vna_set_IF_BW(vna,10e3,1);
    vna_set_average(vna,50,1);
    switch_vna_measurement
    vna_turn_output_on(vna)
    vna_send_average_trigger(vna);
    vna_autoscale(vna,1,1);
    vna_autoscale(vna,1,2);
    actual_resonance_freq = vna_marker_search(vna,1,'min','on',1,1);
    vna_set_trigger_source(vna,'INT');
    actual_resonance_freq = vna_marker_search(vna,1,'min','on',1,1);
    vna_turn_output_off(vna)
    release(daq_handle);
    fprintf('expected resonance freq is: %.5g GHz, actual resonance freq is: %.5g GHz, frequency error is: %.3g MHz \n',...
        expected_freq/(1e9), actual_resonance_freq/(1e9), (actual_resonance_freq - expected_freq)/(1e6));
    
end