function[output_value] = sr844_lockin_query_dispalyed_value(lockin_handle, channel_number)
    
    output_value = str2num(query(lockin_handle, ['outr?' num2str(channel_number)]));

end