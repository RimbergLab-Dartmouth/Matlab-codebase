function [fg_freq] = awg_query_FG_freq(awg_handle)

    fg_freq = str2num(query(awg_handle, 'awgc:FG:freq?'));
    
end

