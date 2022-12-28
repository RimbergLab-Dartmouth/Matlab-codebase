function[state]=n5183b_check_output_state(sig_gen_handle)
     state=str2double(query(sig_gen_handle,':outp?'));
end