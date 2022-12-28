function []=vna_set_IF_BW(vna_handle,IF_bandwidth,channel_number)
     if ~exist('channel_number','var')
         channel_number=str2double(query(vna_handle,':serv:chan:act?'));
     end
     fprintf(vna_handle,[':sens' num2str(channel_number) ':band ' num2str(IF_bandwidth)]);
end
