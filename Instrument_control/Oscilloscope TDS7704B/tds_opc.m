function []=tds_opc(tds_handle)
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    clear tds_handle
    tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
    fopen(tds_handle)
    query(tds_handle,'*OPC?');
    fclose(tds_handle)
    delete(tds_handle)
end