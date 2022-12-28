function[]=vna_send_average_trigger(vna_handle,channel_number)
    if ~exist('channel_number','var')
        channel_number=str2double(query(vna_handle,':serv:chan:act?'));
    end
    fprintf(vna_handle,':trig:sour man');
    fprintf(vna_handle,':trig:aver on');
    fprintf(vna_handle,':trig:sing');
%     average_number=str2double(query(vna_handle,[':sens' num2str(channel_number) ':aver:coun?']));
    query(vna_handle,'*OPC?');
end
