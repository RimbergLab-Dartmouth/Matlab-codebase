function []=awg_run_output_channel_off(awg_handle,run_stop)
    if strcmp(run_stop,'run')
         fprintf(awg_handle,'awgc:run')
     elseif strcmp(run_stop,'stop')
         fprintf(awg_handle,'awgc:stop')
     end      
end