function []=e8257c_set_phase(sg_handle,phase) % phase in degs
   fprintf(sg_handle,[':phas ' num2str(pi/180*phase)]);
end