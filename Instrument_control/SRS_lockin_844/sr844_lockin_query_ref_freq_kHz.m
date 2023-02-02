function[refernce_phase_degs] = sr844_lockin_query_ref_freq_kHz(lockin_handle)

    freq_text = query(lockin_handle, 'freq?');
    refernce_phase_degs = str2num(freq_text)/1e3;

end