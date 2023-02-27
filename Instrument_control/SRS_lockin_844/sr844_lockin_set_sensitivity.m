function[message] = sr844_lockin_set_sensitivity(lockin_handle, sensitivity_in_mV)

    sensitivity_array = [.0001, .0003, .001, .003, .01, .03, ...
        .1, .3, 1, 3, 10, 30, 100, 300, 1e3];
    
    [~, sensitivity_index] = min(abs(sensitivity_array - sensitivity_in_mV));
    if sensitivity_array(sensitivity_index) - sensitivity_in_mV ~= 0 
        disp(['setting to closest sensitivity of ' ...
            num2str(sensitivity_array(sensitivity_index)) 'mV'])
    end
    message = ['SENS ' num2str(sensitivity_index - 1)];
    fprintf(lockin_handle, message)
end