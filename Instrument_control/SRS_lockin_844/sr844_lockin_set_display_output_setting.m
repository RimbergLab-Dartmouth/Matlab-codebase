function[] = sr844_lockin_set_display_output_setting(lockin_handle, display_mode)
% display_mode = 'XY', 'Rvolts', 'RdBm'
    if strcmp(display_mode, 'XY')
        fprintf(lockin_handle, 'DDEF1, 0')
        fprintf(lockin_handle, 'DDEF2, 0')
    elseif strcmp(display_mode, 'Rvolts')
        fprintf(lockin_handle, 'DDEF1, 1')
        fprintf(lockin_handle, 'DDEF2, 1')
    elseif strcmp(display_mode, 'RdBm')
        fprintf(lockin_handle, 'DDEF1, 2')
        fprintf(lockin_handle, 'DDEF2, 1')
    end
    
end