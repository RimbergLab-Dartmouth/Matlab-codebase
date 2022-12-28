function []=tds_horizontal_sample_rate(tds_handle,rate)    % rate in Hz. rate*record_time=record_length(number_points)
      address=tds_handle.PrimaryAddress;
      fclose(tds_handle)
      clear tds_handle
      tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
      fopen(tds_handle)
      fprintf(tds_handle,['hor:mai:sampler ' num2str(rate)]);
      fclose(tds_handle)
     delete(tds_handle)
end
