function []=awg_set_trig_source(awg_handle,trig_source)   %'int' or 'ext'
    fprintf(awg_handle,'TRIG:SOUR %s',trig_source)
end