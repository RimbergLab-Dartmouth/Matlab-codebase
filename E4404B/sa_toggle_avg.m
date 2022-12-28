function []= sa_toggle_avg(sa_handle,on_off)
    fprintf(sa_handle,[':sens1:aver ' num2str(on_off)]);
end

