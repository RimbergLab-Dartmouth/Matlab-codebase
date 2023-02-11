function [] = n9000_set_marker_by_freq(sa_handle, freq, marker_number)
   % marker_number from 1 to 12
    if ~exist('marker_number', 'var')
        marker_number = 1;
    end
    fprintf(sa_handle, [':calc:mark' num2str(marker_number) ':X ' num2str(freq)]);
    
end