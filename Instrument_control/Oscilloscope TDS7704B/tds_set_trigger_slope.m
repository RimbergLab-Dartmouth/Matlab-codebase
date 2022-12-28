function []=tds_set_trigger_slope(tds_handle,slope)   % slope= 'rise' or 'fall'
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    clear tds_handle
    tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
    fopen(tds_handle)
    fprintf(tds_handle,[':trig:a:edge:slo ' slope]);
    fclose(tds_handle)
    delete(tds_handle)
end
