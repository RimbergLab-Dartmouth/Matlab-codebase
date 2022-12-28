function []= n9000_set_RBW(sa_handle,RBW)
    fprintf(sa_handle,[':sense:Bwidth:Res ' num2str(RBW)]);
end

