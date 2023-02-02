function[output_value] = sr844_lockin_query_measured_value(lockin_handle, measurement_type)
% measurement_type = 'X', 'Y', 'Rvolts', 'RdBm', 'theta'

    if strcmp(measurement_type, 'X')
        output_value = str2num(query(lockin_handle, 'outp?1'));
    elseif strcmp(measurement_type, 'Y')
        output_value = str2num(query(lockin_handle, 'outp?2'));
    elseif strcmp(measurement_type, 'Rvolts')
        output_value = str2num(query(lockin_handle, 'outp?3'));
    elseif strcmp(measurement_type, 'RdBm')
        output_value = str2num(query(lockin_handle, 'outp?4'));
    elseif strcmp(measurement_type, 'theta')
        output_value = str2num(query(lockin_handle, 'outp?5'));
    else
        disp('select a valid measurement')
        return
    end

end