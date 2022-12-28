function []=awg_toggle_output(awg_handle,output_state,channel_number)
     if ~exist('channel_number','var')
         channel_number=1;
     end
     if strcmp(output_state,'on')
%          fprintf(awg_handle,'awgc:run')
     elseif strcmp(output_state,'off')
%          fprintf(awg_handle,'awgc:stop')
     end         
     fprintf(awg_handle,['outp' num2str(channel_number) ':stat ' output_state]);
end