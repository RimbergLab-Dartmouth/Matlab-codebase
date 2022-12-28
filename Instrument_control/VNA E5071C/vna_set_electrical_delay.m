function[]=vna_set_electrical_delay(vna_handle,ed_value,channel_number,trace_number)
        if ~exist('channel_number','var')
            channel_number=str2double(query(vna_handle,':serv:chan:act?'));
        end
        if ~exist('trace_number','var')
            trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
        end
        fprintf(vna_handle,[':calc' num2str(channel_number) ':trac' num2str(trace_number) ':corr:edel:time ' num2str(ed_value)]);
end