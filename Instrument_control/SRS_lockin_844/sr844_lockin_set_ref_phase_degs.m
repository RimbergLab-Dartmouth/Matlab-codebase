function[message] = sr844_lockin_set_ref_phase_degs(lockin_handle, ref_phase_degs)
    
    message = ['Phas ' num2str(wrapTo360(ref_phase_degs))];
    fprintf(lockin_handle, message)

end