function[]=awg_create_directory(awg_handle,directory)
     fprintf(awg_handle,[':mmem:mdir "' directory '"']);
end