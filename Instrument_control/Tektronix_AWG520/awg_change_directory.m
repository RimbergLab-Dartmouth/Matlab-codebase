function[]=awg_change_directory(awg_handle,directory)
     fprintf(awg_handle,[':mmem:cdir "' directory '"']);
end