function []=vna_averaging_trigger(vna_handle,on_off)
    %%%% 'on' or 'off'
    fprintf(vna_handle,[':TRIG:AVER ' on_off]);