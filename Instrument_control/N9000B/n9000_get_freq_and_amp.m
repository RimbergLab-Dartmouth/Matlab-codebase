function [freq, amp]=n9000_get_freq_and_amp(sa_handle)

    start_freq = str2double(query(sa_handle,'Freq:start?'));
    stop_freq = str2double(query(sa_handle,'Freq:stop?'));
    fprintf(sa_handle,':INITiate:SAN')
    query(sa_handle,'*OPC?');
    amp_string=query(sa_handle,':TRAC:DATA? TRACE1');
    amp_split_string=strsplit(amp_string,',');
    amp=str2double(amp_split_string);
    freq = linspace(start_freq,stop_freq,length(amp));
        
end