function []=hp8648c_set_frequency(sg_handle,freq)
   fprintf(sg_handle,[':freq ' num2str(freq)]);
end