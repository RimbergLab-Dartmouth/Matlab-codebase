function[]=vna_set_smoothing_aperture(vna_handle,channel_number,trace_number,smoothing_aperture)
    if ~exist('channel_number','var')
        channel_number=str2double(query(vna_handle,':serv:chan:act?'));
    end
    if ~exist('trace_number','var')
       trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
    end

    fprintf(vna_handle,[':calc' num2str(channel_number) ':Trac' num2str(trace_number) ':SMO:APER ' num2str(smoothing_aperture)]);
end
    