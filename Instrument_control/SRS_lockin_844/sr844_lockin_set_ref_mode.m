function[message] = sr844_lockin_set_ref_mode(lockin_handle, ref_mode)
   % ref mode is 'int' or 'ext'
    
    if strcmp('ext', ref_mode)
        ref_mode = 0;
    elseif strcmp('int', ref_mode)
        ref_mode = 1;
    end        
    message = ['FMOD ' num2str(ref_mode)];
    fprintf(lockin_handle, message)

end