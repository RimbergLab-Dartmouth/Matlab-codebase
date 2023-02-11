function [marker_freq, marker_amp] = n9000_marker_peak_search(sa_handle, marker_number)
   % marker_number from 1 to 12
    if ~exist('marker_number', 'var')
        marker_number = 1;
    end
    fprintf(sa_handle,':INITiate:SAN')
    query(sa_handle,'*OPC?');
    fprintf(sa_handle, [':calc:mark' num2str(marker_number) ':max'])
    marker_freq = str2num(query(sa_handle, [':calc:mark' num2str(marker_number) ':X?']));
    marker_amp = str2num(query(sa_handle, [':calc:mark' num2str(marker_number) ':Y?']));
    
end