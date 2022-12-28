function []=awg_set_run_mode(awg_handle,mode)
        % cont - continuous
        %trig - one waveform per trigger
        %gate
        %enh
    fprintf(awg_handle,['awgc:rmode ' mode]);
end