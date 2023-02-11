function[expected_bias_point_params_struct] = ...
    set_bias_point_using_offset_period_struct(desired_gate_point,desired_flux_point, bias_finder_struct, plot_display,set_vna,vna)
    
    if ~exist ('set_vna','var')
        set_vna = 0;
    end
    
    if ~exist ('plot_display','var')
        plot_display = 0;
    end
    
%     load (bias_finder_file, 'flux_zero_voltage', 'flux_period', 'gate_offset', 'gate_period', 'flux_center_freq_mean', 'gate_values_gate', 'res_freqs_gate')
    
% 	[theory_freq_shift]=eigenvalues_v1_2(14.8e9,54.1e9,9,flux_dummies,gate_dummies,1,1,0,0,6);
% 	[theory_freq_shift]=eigenvalues_v1_2(14.8e9,61e9,9,flux_dummies,gate_dummies,1,1,0,0,6);
    
    desired_flux_voltage = bias_finder_struct.flux_zero_voltage + (desired_flux_point * bias_finder_struct.flux_period);
    desired_gate_voltage = (bias_finder_struct.gate_offset + desired_gate_point * bias_finder_struct.gate_period/2);
    
    if set_vna 
        flux_dummies = 2*pi*linspace(desired_flux_point - 0.5, desired_flux_point + 0.5, 31);
        gate_dummies = linspace(desired_gate_point - 2, desired_gate_point + 2, 31);
        [theory_freq_shift]=eigenvalues_v1_2_struct(15.2e9,63e9,9,flux_dummies,gate_dummies,1,1,0,0,6);
        expected_freq = theory_freq_shift(16,16) + bias_finder_struct.flux_center_freq_mean
        daq_handle=daq.createSession('ni');
        addAnalogOutputChannel(daq_handle,'Dev1','ao0','Voltage');
        addAnalogOutputChannel(daq_handle,'Dev1','ao1','Voltage');
        outputSingleScan(daq_handle,[desired_gate_voltage desired_flux_voltage]);
        pause(3);
    end

    if plot_display == 1
        figure
        plot(bias_finder_struct.gate_values_gate,bias_finder_struct.res_freqs_gate,'.','DisplayName','data for phi = 0')
        xlabel('Gate input Voltage (V)')
        ylabel('Resonant Freqs (Hz)')
        title('Raw data, gate sweep at flux zero voltage')
        hold on
        plot(5*((gate_dummies*bias_finder_struct.gate_period) + 2*bias_finder_struct.gate_offset), theory_freq_shift(16,:)+bias_finder_struct.flux_center_freq_mean, ...
            'DisplayName',['theory for phi = ' num2str(desired_flux_point)])
        plot(5*((gate_dummies(16)*bias_finder_struct.gate_period) + 2*bias_finder_struct.gate_offset), ...
            theory_freq_shift(16,16)+bias_finder_struct.flux_center_freq_mean,'x','DisplayName','target point')
        legend show
    end
    
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
    if set_vna
        expected_bias_point_params_struct.flux_dummies = flux_dummies;
        expected_bias_point_params_struct.gate_dummies = gate_dummies; 
        expected_bias_point_params_struct.theory_freq_shift = theory_freq_shift;
        expected_bias_point_params_struct.expected_freq = expected_freq;
        expected_bias_point_params_struct.freq_error = freq_error;
    end
end
