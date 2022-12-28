function []=tds_toggle_channel(tds_handle,channel,on_off)
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    clear tds_handle
    tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
    fopen(tds_handle)
    %%%on_off =0,1
    fprintf(tds_handle,['sel:ch' num2str(channel) ' ' num2str(on_off)]);
    fclose(tds_handle)
    delete(tds_handle)
end