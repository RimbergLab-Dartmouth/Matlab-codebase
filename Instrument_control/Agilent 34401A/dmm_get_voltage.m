function [voltage]=dmm_get_voltage(dmm_handle)
    voltage=str2double(query(dmm_handle,'meas:volt:DC?'));
end

