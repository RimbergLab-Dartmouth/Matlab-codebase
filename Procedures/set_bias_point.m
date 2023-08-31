function[] = set_bias_point(desired_gate_point,desired_flux_point, bias_finder_struct, dmm_1, dmm_2)

    desired_flux_voltage = bias_finder_struct.flux_zero_voltage + (desired_flux_point * bias_finder_struct.flux_period)
    desired_gate_voltage = (bias_finder_struct.gate_offset + desired_gate_point * bias_finder_struct.gate_period/2)
    [~, theory_freq_shift] = res_freq_expected_for_Jules_sample(desired_gate_point, desired_flux_point);
    expected_freq = theory_freq_shift + bias_finder_struct.flux_center_freq_mean
    daq_handle=daq.createSession('ni');
    addAnalogOutputChannel(daq_handle,'Dev1','ao0','Voltage');
    addAnalogOutputChannel(daq_handle,'Dev1','ao1','Voltage');
    outputSingleScan(daq_handle,[desired_gate_voltage desired_flux_voltage]);
    pause(3);
    flux_voltage_status = dmm_get_voltage(dmm_2)
    gate_voltage_status = dmm_get_voltage(dmm_1)
    
end