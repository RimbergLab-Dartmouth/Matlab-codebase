function[BW,Q,center,loss]=vna_find_BW(vna_handle,BW_thrs,marker_number,channel_number,trace_number)
   % use in conjunction with marker_search or set_marker 
    if ~exist('channel_number','var')
       channel_number=str2double(query(vna_handle,':serv:chan:act?'));
    end
    if ~exist('trace_number','var')
        trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
    end 
    fprintf(vna_handle,[':calc' num2str(channel_number) ':par' num2str(trace_number) ':sel']);
    fprintf(vna_handle,[':calc' num2str(channel_number) ':trac' num2str(trace_number) ':mark'...
        num2str(marker_number) ':BWID:THR ' num2str(BW_thrs)]);
    BW_data=query(vna_handle,[':calc' num2str(channel_number) ':mark' num2str(marker_number) ':'...
        'BWID:Data?']);
    BW_data=strsplit(BW_data,',');
    BW=str2double(BW_data(1,1));
    center=str2double(BW_data(1,2));
    Q=str2double(BW_data(1,3));
    loss=str2double(BW_data(1,4));
end