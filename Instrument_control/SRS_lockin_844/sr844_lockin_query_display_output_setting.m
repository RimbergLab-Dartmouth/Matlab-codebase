function[display_mode] = sr844_lockin_query_display_output_setting(lockin_handle)
% display_mode = 'XY', 'Rvolts', 'RdBm'
    channel_1_mode = query(lockin_handle, 'DDEF1?');
    channel_2_mode = query(lockin_handle, 'DDEF2?');
    
    if channel_1_mode == 0 && channel_2_mode == 0
        display_mode = 'XY';
    elseif channel_1_mode == 1 && channel_2_mode == 1
        display_mode = 'Rvolts_theta_degs';
    elseif channel_1_mode == 2 && channel_2_mode == 1
        display_mode = 'RdBm_theta_degs';
    end
    
end