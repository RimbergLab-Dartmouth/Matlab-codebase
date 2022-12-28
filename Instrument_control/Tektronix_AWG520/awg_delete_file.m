function[]=awg_delete_file(awg_handle,file)
     if isempty(strfind(file,'/'))
         dir=query(awg_handle,':mmem:cdir?');
         dir=dir(2:end-2);
         file=[dir '/' file];
     end
     fprintf(awg_handle,[':mmem:del "' file '"']);
end