function [freq_reqd_in_MHz, phase_reqd_in_degs, amp_reqd_in_VPP] = novatech_readout_settings(novatech_handle, channel_number)
% channel number = 0 to 3
    %%% get rid of any previous read commands
    while novatech_handle.NumBytesAvailable ~=0
        readline(novatech_handle);
    end
    
    writeline(novatech_handle, 'QUE')
    for m_channel = 1 : 5
        readout_string = readline(novatech_handle);
        if m_channel < 5
            text_string = strsplit(readout_string);
            freq(m_channel) = hex2dec(text_string(1))/1e7;
            phase(m_channel) = round(hex2dec(text_string(2))/16383 *360, 4);
            amp(m_channel) = round(hex2dec(text_string(3))/1023, 4);
        end
    end
    freq_reqd_in_MHz = freq(channel_number + 1);
    phase_reqd_in_degs = phase(channel_number + 1);
    amp_reqd_in_VPP = amp(channel_number + 1);
    while novatech_handle.NumBytesAvailable ~=0
        readline(novatech_handle);
    end
end