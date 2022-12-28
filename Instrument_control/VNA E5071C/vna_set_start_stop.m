function[]=vna_set_start_stop(vna_handle,start_freq,stop_freq,channel_number)
        if ~exist('channel_number','var')
            channel_number=str2double(query(vna_handle,':serv:chan:act?'));
        end
        freq_settings=[':sens' num2str(channel_number) ':freq:start ' num2str(start_freq) ' ;stop ' num2str(stop_freq)];
        fprintf(vna_handle,freq_settings);
end