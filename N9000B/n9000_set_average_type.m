function []= n9000_set_average_type(sa_handle,average_type)
    %%%% average type can be :  'RMS', 'Log', 'Scalar'
    fprintf(sa_handle,[':AVERage:TYPE ' average_type]);
end

