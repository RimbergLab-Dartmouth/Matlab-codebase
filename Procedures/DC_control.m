function[] = DC_control(desired_gate_voltage,desired_flux_voltage)

    
    %% set DC voltages for the gate and flux lines and obtain voltage reading
    % gate period 5.1, flux period 0.53
    daq_handle=daq.createSession('ni');
    addAnalogOutputChannel(daq_handle,'Dev1','ao0','Voltage');
    addAnalogOutputChannel(daq_handle,'Dev1','ao1','Voltage');
    outputSingleScan(daq_handle,[desired_gate_voltage desired_flux_voltage]);
    pause(3);
    dmm_1 = evalin('base', 'dmm_1');
    dmm_2 = evalin('base', 'dmm_2');
    flux_voltage_status = dmm_get_voltage(dmm_2);
    gate_voltage_status = dmm_get_voltage(dmm_1);
    fprintf('desired flux voltage is: %.4g mV, actual flux voltage is: %.4gmV \n',desired_flux_voltage*1e3, flux_voltage_status*1e3);
    fprintf('desired gate voltage is: %.4g mV, actual gate voltage is: %.4gmV \n',desired_gate_voltage*10, gate_voltage_status*1e3);
    
    
end