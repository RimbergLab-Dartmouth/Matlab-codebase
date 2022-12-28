function []=vna_marker_search_domain(vna_handle,start_freq,stop_freq,channel_number,trace_number)
     if ~exist('channel_number','var')
       channel_number=str2double(query(vna_handle,':serv:chan:act?'));
    end
    if ~exist('trace_number','var')
        trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
    end 
    fprintf(vna_handle,[':calc' num2str(channel_number) ':par' num2str(trace_number) ':sel']);
    fprintf(vna_handle,[':calc' num2str(channel_number) ':func:dom:star ' num2str(start_freq) '; stop ' num2str(stop_freq)]);
    [':calc' num2str(channel_number) ':func:dom:star ' num2str(start_freq) '; stop'...
        ' ' num2str(stop_freq)]
end

%%% Doesn't work - no error %%%%%%%%