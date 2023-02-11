function [fg_amp_Vpp] = awg_query_FG_amp(awg_handle, channel_number)

    fg_amp_Vpp = str2num(query(awg_handle, ['awgc:FG' num2str(channel_number) ':volt?']));
    
end