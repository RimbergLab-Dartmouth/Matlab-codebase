function[power_in_dBm] = convert_watts_to_dBm(power_in_watts)
    power_in_dBm = 10.*log10(power_in_watts./1e-3);
end