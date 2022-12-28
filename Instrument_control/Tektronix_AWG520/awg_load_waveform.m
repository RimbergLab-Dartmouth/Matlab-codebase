function []=awg_load_waveform(awg_handle,channel,file)
    fprintf(awg_handle,['sour' num2str(channel) ':func:user "' file '"'])
end