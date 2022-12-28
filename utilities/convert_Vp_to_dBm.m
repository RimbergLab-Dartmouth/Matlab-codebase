function [power_dBm] = convert_Vp_to_dBm(voltage_peak)
    power_watts = voltage_peak.^2 /50/ 2; % power in watts is for Vrms
    power_dBm = 10.*log10(power_watts./1e-3);
end