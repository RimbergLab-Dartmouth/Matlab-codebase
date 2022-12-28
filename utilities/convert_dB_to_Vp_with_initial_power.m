function [final_voltage] = convert_dB_to_Vp_with_initial_power(factor_in_dB, initial_power_in_dBm)
    [~,initial_power_in_watts] = convert_dBm_to_Vp(initial_power_in_dBm);
    power_in_watts = initial_power_in_watts*10.^(factor_in_dB./10);
    final_voltage = sqrt(2*power_in_watts *50);
end