function[]=vna_set_format(vna_handle,format,channel_number,trace_number)
%mlog, uph-expanded phase, phas-phase, gdel-group delay, swr, pol-polar,
%pph-positive phase
        if ~exist('channel_number','var')
            channel_number=str2double(query(vna_handle,':serv:chan:act?'));
        end
        if ~exist('trace_number','var')
            trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
        end    
        fprintf(vna_handle,[':calc' num2str(channel_number) ':par' num2str(trace_number) ':sel']);
        fprintf(vna_handle,[':calc' num2str(channel_number) ':form ' format]);
end