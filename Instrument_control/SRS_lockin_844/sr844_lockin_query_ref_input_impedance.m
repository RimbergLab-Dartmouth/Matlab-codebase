function[ref_impedance] = sr844_lockin_query_ref_input_impedance(lockin_handle)
    
    ref_impedance = query(lockin_handle, 'REFZ?');
    if ref_impedance == 0 
        ref_impedance = 50;
    elseif ref_impedance == 1
        ref_impedance = 1e4;
    end
    
end