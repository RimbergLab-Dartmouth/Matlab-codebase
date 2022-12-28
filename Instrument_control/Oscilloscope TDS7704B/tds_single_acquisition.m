function []=tds_single_acquisition(tds_handle,single_acq_on)
    if single_acq_on==1
        state='seq';
    else
        state='runst';
    end
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    clear tds_handle
    tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
    fopen(tds_handle)
    fprintf(tds_handle,['acq:stopa ' state]);
    fclose(tds_handle)
    delete(tds_handle)
end
