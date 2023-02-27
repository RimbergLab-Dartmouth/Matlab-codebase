function[message] = sr844_lockin_set_ref_freq(lockin_handle, ref_freq_kHz)
   % freq from 25.4kHz to 200MHz

    message = ['Freq ' num2str(ref_freq_kHz)];
    fprintf(lockin_handle, message)

end