function []=vna_marker_tracking(vna_handle,marker_number,on_off,channel_number,trace_number)
    if ~exist('channel_number','var')
       channel_number=str2double(query(vna_handle,':serv:chan:act?'));
    end
    if ~exist('trace_number','var')
        trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
    end 
    fprintf(vna_handle,[':calc' num2str(channel_number) ':par' num2str(trace_number) ':sel']);
    fprintf(vna_handle,[':calc' num2str(channel_number) ':mark' num2str(marker_number) ':func:Trac ' on_off]);
end