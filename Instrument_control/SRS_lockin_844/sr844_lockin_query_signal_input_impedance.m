function[input_impedance] = sr844_lockin_query_signal_input_impedance(lockin_handle)
    
    input_impedance = query(lockin_handle, 'INPZ?');
    if input_impedance == 0 
        input_impedance = 50;
    elseif input_impedance == 1
        input_impedance = 1e6;
    end
    
end