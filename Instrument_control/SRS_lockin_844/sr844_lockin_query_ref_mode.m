function[ref_mode] = sr844_lockin_query_ref_mode(lockin_handle)
   % ref mode is 'int' or 'ext'
    
    ref_mode_text = query(lockin_handle, 'FMOD?');
    if strcmp(ref_mode_text, '1')
        ref_mode = 'internal';
    elseif strcmp(ref_mode_text, '0')
        ref_mode = 'external';
    end

end