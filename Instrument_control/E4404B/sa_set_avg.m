function []= sa_set_avg(sa_handle,avg_number,on_off)
    if ~exist('on_off','var')
        on_off='on';
    end
    fprintf(sa_handle,[':sens1:aver ' num2str(on_off)]);
    fprintf(sa_handle,[':sens1:aver:coun ' num2str(avg_number)]);
    fprintf(sa_handle,':sens1:aver:cle');
    query(sa_handle,'*OPC?');
end

