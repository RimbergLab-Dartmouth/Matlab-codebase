function []=tds_set_trigger_source(tds_handle,channel)
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    clear tds_handle
    tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
    fopen(tds_handle)
    if ~exist('channel','var')
        channel=str2num(query(tds_handle,'data:source?'));
    end
    fprintf(tds_handle,['trig:a:edge:sou ch' num2str(channel)]);
    fclose(tds_handle)
    delete(tds_handle)
end
