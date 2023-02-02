function[] = sr844_lockin_set_signal_input_impedance(lockin_handle, input_impedance)

    if input_impedance ~=50 && input_impedance ~= 1e6
        disp('enter valid input impedance - 50 or 1e6 (ohm)')
    elseif input_impedance == 50
        input_impedance = 0;
    elseif input_impedance == 1e6
        input_impedance = 1;
    end
    fprintf(lockin_handle, ['INPZ ' num2str(input_impedance)])
end