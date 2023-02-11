function [] = awg_set_FG_shape(awg_handle, channel_number, shape)
% shape : 'sin', 'tri', 'squ', 'ramp', 'pulse', 'dc'

    fprintf(awg_handle, ['awgc:FG' num2str(channel_number) ':func ' shape])

end