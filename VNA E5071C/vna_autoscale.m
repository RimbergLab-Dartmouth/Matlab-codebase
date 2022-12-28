function[]=vna_autoscale(vna_handle,channel_number,trace_number)
        if ~exist('channel_number','var')
            channel_number=str2double(query(vna_handle,':serv:chan:act?'));
        end
        if ~exist('trace_number','var')
            trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
        end
        fprintf(vna_handle,[':disp:wind' num2str(channel_number) ':trac' num2str(trace_number) ':y:auto']);
end
          