function [] = awg_FG_set_freq(awg_handle, freq)
% freq in Hz, 1 Hz to 100MHz
% weirdly, changes both channel frequencies simultaneously. cannot set
% independently. 

    fprintf(awg_handle, ['awgc:FG:freq ' num2str(freq)])
    
end

