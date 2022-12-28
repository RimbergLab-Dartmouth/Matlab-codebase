function []= n9000_set_center_span(sa_handle,center,span)
    fprintf(sa_handle,[':sens1:freq:center ' num2str(center) ' ;span ' num2str(span)]);
end

