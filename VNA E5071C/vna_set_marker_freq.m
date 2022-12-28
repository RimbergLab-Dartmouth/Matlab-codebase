function[]=vna_set_marker_freq(vna_handle,marker_number,freq,channel_number)
     if ~exist('channel_number','var')
        channel_number=str2double(query(vna_handle,':serv:chan:act?'));
     end
     if marker_number==0
         marker_number='ref';
     else
         marker_number=num2str(marker_number);
     end
     fprintf(vna_handle,[':calc' num2str(channel_number) ':mark' marker_number ':X ' num2str(freq)]);
end
