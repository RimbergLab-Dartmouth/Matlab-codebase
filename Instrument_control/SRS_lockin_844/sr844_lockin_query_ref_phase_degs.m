function[refernce_phase_degs] = sr844_lockin_query_ref_phase_degs(lockin_handle)

    phase_text = query(lockin_handle, 'Phas?');
    refernce_phase_degs = wrapTo360(str2num(phase_text));

end