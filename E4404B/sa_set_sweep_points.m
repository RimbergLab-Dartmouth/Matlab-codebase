function []=sa_set_sweep_points(sa_handle,sweep_points)
    fprintf(sa_handle,[':sense:sweep:poin ' num2str(sweep_points)]);
end