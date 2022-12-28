function []= sa_set_RW(sa_handle,RW)
    fprintf(sa_handle,[':sense:Bwidth:Res ' num2str(RW)]);
end

