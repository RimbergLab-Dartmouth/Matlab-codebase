function[filter_slope_in_dB_per_oct] = sr844_lockin_query_filter_slope(lockin_handle)

    filter_slope_array = [0, 6, 12, 18, 24];    
    filter_slope_text = query(lockin_handle, 'OFSL?');
    filter_slope_index = str2num(filter_slope_text);
    filter_slope_in_dB_per_oct = filter_slope_array(filter_slope_index + 1);
    
end