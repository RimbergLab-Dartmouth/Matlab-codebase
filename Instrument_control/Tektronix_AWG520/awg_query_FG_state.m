function [FG_state] = awg_query_FG_state(awg_handle) % on_off : 'on', 'off'

    FG_state_string = query(awg_handle, 'AWGC:FG?');
    
    if str2num(FG_state_string) == 1
        FG_state = 'field generator mode';
    elseif str2num(FG_state_string) == 0
        FG_state = 'AWG mode';
    end

end