function []=awg_set_ref_source(awg_handle,ref_source)   %'int' or 'ext'
    fprintf(awg_handle,'ROSC:SOUR %s',ref_source)
end