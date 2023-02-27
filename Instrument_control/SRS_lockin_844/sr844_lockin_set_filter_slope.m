function[message] = sr844_lockin_set_filter_slope(lockin_handle, slope_dB_per_oct)

    filter_slope_array = [0, 6, 12, 18, 24];
    
    [~, filter_slope_index] = min(abs(filter_slope_array - slope_dB_per_oct));
    if filter_slope_array(filter_slope_index) - slope_dB_per_oct ~= 0 
        disp(['setting to closest filter slope of ' ...
            num2str(filter_slope_array(filter_slope_index)) 'dB/oct'])
    end
    message = ['OFSL ' num2str(filter_slope_index - 1)];
    fprintf(lockin_handle, message)
end