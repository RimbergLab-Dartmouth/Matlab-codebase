function []=vna_set_trigger_source(vna_handle,trigger_source)
    %%%% MAN: manual, INT: internal, EXT: external   %%%%%
    fprintf(vna_handle,[':TRIG:SOUR ' trigger_source]);
end