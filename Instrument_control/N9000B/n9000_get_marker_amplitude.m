function [marker_amplitude, marker_freq] = n9000_get_marker_amplitude(sa_handle, marker_number)
% marker_number from 1 to 12

    if ~exist('marker_number', 'var')
        marker_number = 1;
    end
    fprintf(sa_handle,':INITiate:SAN')
    query(sa_handle,'*OPC?');
    marker_amplitude = str2num(query(sa_handle, [':calc:mark' num2str(marker_number) ':Y?']));
    marker_freq = str2num(query(sa_handle, [':calc:mark' num2str(marker_number) ':X?']));
    
end