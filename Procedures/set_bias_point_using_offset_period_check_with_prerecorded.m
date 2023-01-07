function[expected_bias_point_params_struct] = ...
    set_bias_point_using_offset_period_check_with_prerecorded(desired_gate_point,desired_flux_point, bias_finder_struct, pre_recorded_struct,set_vna,vna)
    
    if ~exist ('set_vna','var')
        set_vna = 0;
    end
    
    desired_flux_voltage = bias_finder_struct.flux_zero_voltage + (desired_flux_point * bias_finder_struct.flux_period);
    desired_gate_voltage = (bias_finder_struct.gate_offset + desired_gate_point * bias_finder_struct.gate_period/2);
    
    [~, closest_gate_point] = min(abs(mod(desired_gate_point, 2) - circshift(pre_recorded_struct.gate_values, (length(pre_recorded_struct.gate_values) - 1)/2)));
    [~, closest_flux_point] = min(abs(mod(desired_flux_point, 1) - pre_recorded_struct.flux_values - 1));
    
    mod(closest_gate_point - (length(pre_recorded_struct.gate_values) - 1)/2, length(pre_recorded_struct.gate_values))
    closest_flux_point
    expected_freq = pre_recorded_struct.res_freqs(closest_flux_point, closest_gate_point);
    
    daq_handle=daq.createSession('ni');
    addAnalogOutputChannel(daq_handle,'Dev1','ao0','Voltage');
    addAnalogOutputChannel(daq_handle,'Dev1','ao1','Voltage');
    outputSingleScan(daq_handle,[desired_gate_voltage desired_flux_voltage]);
    pause(3);

    if set_vna == 1
        vna_set_power(vna, -65)
        vna_set_center_span(vna,expected_freq,25e6,1);
        vna_set_sweep_points(vna,1601,1);
        vna_set_IF_BW(vna,10e3,1);
        vna_set_average(vna,30,1);
        switch_vna_measurement
        vna_turn_output_on(vna)
        vna_send_average_trigger(vna);
        vna_autoscale(vna,1,1);
        vna_autoscale(vna,1,2);
        actual_resonance_freq = vna_marker_search(vna,1,'min','on',1,1);
        vna_set_trigger_source(vna,'INT');
        actual_resonance_freq = vna_marker_search(vna,1,'min','on',1,1)
%         vna_turn_output_off(vna)
        release(daq_handle);
        freq_error = (actual_resonance_freq - expected_freq)
    else 
        freq_error = 0;
    end
    expected_bias_point_params_struct.desired_flux_voltage = desired_flux_voltage;
    expected_bias_point_params_struct.desired_gate_voltage = desired_gate_voltage; 
%     expected_bias_point_params_struct.flux_dummies = flux_dummies;
%     expected_bias_point_params_struct.gate_dummies = gate_dummies; 
%     expected_bias_point_params_struct.theory_freq_shift = theory_freq_shift;
    expected_bias_point_params_struct.expected_freq = expected_freq;
    expected_bias_point_params_struct.freq_error = freq_error;
end
