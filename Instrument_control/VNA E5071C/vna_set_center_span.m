function []= vna_set_center_span(vna_handle,center_freq,span_freq,channel_number)
        if ~exist('channel_number','var')
            channel_number=str2double(query(vna_handle,':serv:chan:act?'));
        end
        freq_settings=[':sens' num2str(channel_number) ':freq:center ' num2str(center_freq) ' ;span ' num2str(span_freq)];
        fprintf(vna_handle,freq_settings);
end