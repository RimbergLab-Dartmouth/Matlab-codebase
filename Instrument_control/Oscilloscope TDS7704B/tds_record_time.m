function []=tds_record_time(tds_handle,record_time)   % this is time for whole trace (in s). time/div=time/10
     address=tds_handle.PrimaryAddress;
     fclose(tds_handle)
     clear tds_handle
     tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
     fopen(tds_handle)
     fprintf(tds_handle,['hor:sca ' num2str(record_time/10)]);
     fclose(tds_handle)
     delete(tds_handle)
end