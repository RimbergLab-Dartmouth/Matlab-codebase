function [] = hp_6612c_set_voltage(hp_handle,voltage_value,output_state)
    fprintf(hp_handle,['volt ' num2str(voltage_value)]);
    fprintf(hp_handle,['output ' output_state]);
end