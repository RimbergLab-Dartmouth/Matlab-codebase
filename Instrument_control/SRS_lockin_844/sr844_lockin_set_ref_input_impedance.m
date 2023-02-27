function[] = sr844_lockin_set_ref_input_impedance(lockin_handle, ref_impedance)

    if ref_impedance ~=50 && ref_impedance ~= 1e4
        disp('enter valid input impedance - 50 or 1e4 (ohm)')
    elseif ref_impedance == 50
        ref_impedance = 0;
    elseif ref_impedance == 1e4
        ref_impedance = 1;
    end
    fprintf(lockin_handle, ['REFZ ' num2str(ref_impedance)])
end