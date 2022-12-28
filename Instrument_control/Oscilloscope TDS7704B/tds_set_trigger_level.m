function []=tds_set_trigger_level(tds_handle,level)   % level in volts  sets to 50% if no level value
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    clear tds_handle
    tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
    fopen(tds_handle)
    if ~exist('level','var')
        fprintf(tds_handle,['trig:a:lev ' num2str(level)]);
    else
        fprintf(tds_handle,'trig:a');    
    end
    fclose(tds_handle)
    delete(tds_handle)
end