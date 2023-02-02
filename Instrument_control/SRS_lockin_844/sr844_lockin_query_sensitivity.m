function[sensitivity_in_mV] = sr844_lockin_query_sensitivity(lockin_handle)

    sensitivity_array = [.0001, .0003, .001, .003, .01, .03, ...
        .1, .3, 1, 3, 10, 30, 100, 300, 1e3];
    
    sensitivity_text = query(lockin_handle, 'SENS?');
    sensitivity_index = str2num(sensitivity_text);
    sensitivity_in_mV = sensitivity_array(sensitivity_index + 1);
end