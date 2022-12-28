function [x_marker, y_marker_primary, y_marker_secondary]=vna_marker_search(vna_handle,marker_number,...
    search_type,marker_on,channel_number,trace_number)
%  'max' - maximum
%  'min' - minimum
%  'peak' - peak
%  'lpe' - peak to the left
%  'rpe' - peak to the right
%  'targ' - target
%  'ltar' - target to the left
%  'rtar' - target to the right
    if ~exist('marker_on','var')
        marker_on='on';
    end
    if ~exist('channel_number','var')
       channel_number=str2double(query(vna_handle,':serv:chan:act?'));
    end
    if ~exist('trace_number','var')
        trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
    end 
    fprintf(vna_handle,[':calc' num2str(channel_number) ':par' num2str(trace_number) ':sel']);
    fprintf(vna_handle,[':calc' num2str(channel_number) ':trac' num2str(trace_number) ':ma'...
        'rk' num2str(marker_number) ':func:type ' search_type]);
    fprintf(vna_handle,[':calc' num2str(channel_number) ':trac' num2str(trace_number) ':ma'...
        'rk' num2str(marker_number) ':func:exec']);
    vna_display_marker(vna_handle,marker_number,'on',channel_number);
    [x_marker, y_marker_primary, y_marker_secondary]=vna_get_marker_data(vna_handle,channel_number,trace_number);
    if strcmpi(marker_on,'on')
        vna_display_marker(vna_handle,marker_number,'on',channel_number)
    end
end
