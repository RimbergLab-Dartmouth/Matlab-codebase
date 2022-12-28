function[output]=awg_list_files(awg_handle)
    output = query(awg_handle,'mmem:cat?');
end