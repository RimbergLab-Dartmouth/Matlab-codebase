function[message] = sr844_lockin_set_time_constant(lockin_handle, time_constant_in_s)

    time_constant_array = [1e-4, 3e-4, 1e-3, 3e-3, 1e-2, 3e-2, ...
        .1, .3, 1, 3, 10, 30, 100, 300, 1e3, 3e3, 1e4, 3e4];
    
    [~, time_constant_index] = min(abs(time_constant_array - time_constant_in_s));
    if time_constant_array(time_constant_index) - time_constant_in_s ~= 0 
        disp(['setting to closest time constant of ' ...
            num2str(time_constant_array(time_constant_index)) 's'])
    end
    message = ['OFLT ' num2str(time_constant_index - 1)];
    fprintf(lockin_handle, message)
end