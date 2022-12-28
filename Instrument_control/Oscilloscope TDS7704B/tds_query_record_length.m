function [record_length]=tds_query_record_length(tds_handle)     % number of points in entire trace
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    clear tds_handle
    tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
    fopen(tds_handle)
    record_length=str2double(query(tds_handle,'hor:reco?'));
    fclose(tds_handle)
    delete(tds_handle)
end