function []= n9000_set_trace_type(sa_handle,type)  % type = 'write', 'average', 'maxhold', 'minhold'
    fprintf(sa_handle,[':TRACe:TYPE ' type]);
end