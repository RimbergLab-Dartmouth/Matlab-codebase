function[time_constant_in_s] = sr844_lockin_query_time_constant(lockin_handle)

    time_constant_array = [1e-4, 3e-4, 1e-3, 3e-3, 1e-2, 3e-2, ...
        .1, .3, 1, 3, 10, 30, 100, 300, 1e3, 3e3, 1e4, 3e4];
    
    time_constant_text = query(lockin_handle, 'OFLT?');
    time_constant_index = str2num(time_constant_text);
    time_constant_in_s = time_constant_array(time_constant_index + 1);
end