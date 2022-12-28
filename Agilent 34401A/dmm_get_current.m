function [voltage]=dmm_get_current(dmm_handle)
    voltage=str2double(query(dmm_handle,'meas:curr:DC?'));
end

