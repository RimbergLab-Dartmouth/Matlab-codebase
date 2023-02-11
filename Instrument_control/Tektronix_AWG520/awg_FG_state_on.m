function [] = awg_FG_state_on(awg_handle, on_off) % on_off : 'on', 'off'

    fprintf(awg_handle, ['AWGC:FG ' on_off])

end