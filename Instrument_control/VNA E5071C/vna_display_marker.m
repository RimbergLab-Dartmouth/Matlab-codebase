function[]=vna_display_marker(vna_handle,marker_number,off_on,channel_number)
%reference marker number=0
     if ~exist('channel_number','var')
         channel_number=str2double(query(vna_handle,':serv:chan:act?'));
     end
     if marker_number==0
         fprintf(vna_handle,[':calc' num2str(channel_number) ':mark:ref ' off_on]);
     else
         fprintf(vna_handle,[':calc' num2str(channel_number) ':mark' num2str(marker_number) ' ' off_on]);
     end
end     
