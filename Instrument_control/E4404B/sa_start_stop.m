function []= sa_start_stop(sa_handle,start,stop)
    fprintf(sa_handle,[':sens1:freq:start ' num2str(start) ' ;stop ' num2str(stop)]);
end

