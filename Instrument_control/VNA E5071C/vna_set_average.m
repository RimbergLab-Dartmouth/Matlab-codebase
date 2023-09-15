
function[]=vna_set_average(vna_handle,average_number,channel_number,average_time)
    if ~exist('channel_number','var')
        channel_number=str2double(query(vna_handle,':serv:chan:act?'));
    end
    if average_number==0
        fprintf(vna_handle,[':sens' num2str(channel_number) ':aver off']);
    else
        fprintf(vna_handle,[':sens' num2str(channel_number) ':aver on']);
        fprintf(vna_handle,[':sens' num2str(channel_number) ':aver:coun ' num2str(average_number)]);
        fprintf(vna_handle,[':sens' num2str(channel_number) ':aver:cle']);
        query(vna_handle,'*OPC?');
    end    
end
    