function [FG_shape] = awg_query_FG_shape(awg_handle, channel_number)
% shape : 'sin', 'tri', 'squ', 'ramp', 'pulse', 'dc'

    FG_shape = query(awg_handle, ['awgc:FG' num2str(channel_number) ':func?']);

end