function[message] = novatech_set_freq(novatech_handle, freq_in_MHz, channel_number) %channel number : 0 to 3, freq : .0000001 to 171.1276031 MHz or 'DC'
    % frequency value in MHz
    if isa(freq_in_MHz,'double')
        if floor(freq_in_MHz) == freq_in_MHz
            decimal_append = '.0';
        else
            decimal_append = '';
        end
        message = ['F' num2str(channel_number) ' ' num2str(freq_in_MHz, 10) decimal_append];
    elseif isa(freq_in_MHz, 'char') && strcmp(freq_in_MHz, 'DC')
        message = ['F' num2str(channel_number) ' 0.00'];
    end
    writeline(novatech_handle, message)
end
