function [error] =  bifurcated_s11_kerr_flucs_error_calc(data_real, data_imag, res_freq_GHz, detunings_MHz, prob_at_detunings, input_power_at_sample_dBm, kappa_int_MHz, kappa_ext_MHz, kerr_MHz)
    if prob_at_detunings < 0
        error = 1e15;
        return
    end
    if prob_at_detunings > 1
        error = 1e16;
        return
    end
    
    [theory_real, theory_imag] = ...
    generate_bifurcated_s11_kerr_flucs_for_single_detuning_power(res_freq_GHz, detunings_MHz, input_power_at_sample_dBm, prob_at_detunings, kappa_int_MHz, kappa_ext_MHz, kerr_MHz);
    
    error = mean(sqrt((theory_real-data_real).^2 + (theory_imag - data_imag).^2));
    
end