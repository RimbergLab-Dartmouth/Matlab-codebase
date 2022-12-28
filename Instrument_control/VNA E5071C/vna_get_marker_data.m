function [x_marker y_marker_primary y_marker_secondary]=vna_get_marker_data(vna_handle,marker_number,...
    channel_number,trace_number)
    if ~exist('channel_number','var')
       channel_number=str2double(query(vna_handle,':serv:chan:act?'));
    end
    if ~exist('trace_number','var')
        trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
    end 
    fprintf(vna_handle,[':calc' num2str(channel_number) ':par' num2str(trace_number) ':sel']);
    x_marker=str2double(query(vna_handle,[':calc' num2str(channel_number) ':mark' num2str(marker_number) ':X?']));
    y_marker=query(vna_handle,[':calc' num2str(channel_number) ':mark' num2str(marker_number) ':Y?']);
    y_data1=strsplit(y_marker,',');
    y=str2double(y_data1);
    y_marker_primary=y(1:2:end);
    y_marker_secondary=y(2:2:end);