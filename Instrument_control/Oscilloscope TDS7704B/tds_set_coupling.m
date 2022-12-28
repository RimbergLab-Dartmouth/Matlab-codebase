function[]=tds_set_coupling(tds_handle,channel,coupling)
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    clear tds_handle
    tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
    fopen(tds_handle)
    fprintf(tds_handle,['ch' num2str(channel) ':coup ' coupling]);
    fclose(tds_handle)
    delete(tds_handle)
end