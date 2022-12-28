function[]=n5183b_toggle_modulation(sig_gen_handle,on_off)
     fprintf(sig_gen_handle,[':outp:mod:stat ' on_off]);
end