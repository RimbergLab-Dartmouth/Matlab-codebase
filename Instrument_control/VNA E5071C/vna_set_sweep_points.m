function[]=vna_set_sweep_points(vna_handle,number_points,channel_number)
       if ~exist('channel_number','var')
           channel_number=str2double(query(vna_handle,':serv:chan:act?'));
       end
       fprintf(vna_handle,[':sens' num2str(channel_number) ':swe:poin ' num2str(number_points)]);
end