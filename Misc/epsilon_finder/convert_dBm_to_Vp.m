function[voltage_peak, power_in_watts] = convert_dBm_to_Vp(power_in_dBm)
    power_in_watts = 1e-3*10.^(power_in_dBm./10);
    voltage_peak = sqrt(2*power_in_watts *50); % power in watts corresponds to V_RMS. hence the factor of 2 in the sqrt.
end