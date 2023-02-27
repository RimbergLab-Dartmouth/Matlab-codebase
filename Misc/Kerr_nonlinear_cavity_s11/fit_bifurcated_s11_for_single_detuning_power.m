function[theory_real_state_1, theory_imag_state_1, theory_log_mag_state_1, theory_phase_state_1, ...
    theory_real_state_2, theory_imag_state_2, theory_log_mag_state_2, theory_phase_state_2, theory_probability, goodness_fit] = ...
    fit_bifurcated_s11_for_single_detuning_power(data_real, data_imag, res_freq_GHz, input_freqs_GHz, input_power_at_sample_dBm, kappa_int_MHz, kappa_ext_MHz, kerr_MHz)
    
    detunings_MHz = (input_freqs_GHz - res_freq_GHz)*1e3;
    detunings_MHz(1);
    prob_guess = 0.75;
    for i = 1 : length(detunings_MHz)
        err = @(p) bifurcated_s11_error_calc(data_real(i), data_imag(i), res_freq_GHz, detunings_MHz(i),p, input_power_at_sample_dBm, kappa_int_MHz, kappa_ext_MHz, kerr_MHz);
        options=optimset('MaxIter',500000,'MaxFunEvals',500000,'TolFun',1e-14,'TolX',1e-14);
        [theory_probability(i),goodness_fit(i),flag,output]=fminsearch(err,prob_guess,options);
    end
    
%     [theory_real_state_1, theory_imag_state_1, theory_log_mag_state_1, theory_phase_state_1] = ...
%     generate_bifurcated_s11_for_single_detuning_power(res_freq_GHz, detunings_MHz, input_power_at_sample_dBm, zeros(1,length(theory_probability)), kappa_int_MHz, kappa_ext_MHz, kerr_MHz);

    [theory_real_state_1, theory_imag_state_1, theory_log_mag_state_1, theory_phase_state_1] = ...
    generate_bifurcated_s11_for_single_detuning_power(res_freq_GHz, detunings_MHz, input_power_at_sample_dBm, theory_probability, kappa_int_MHz, kappa_ext_MHz, kerr_MHz);

    random_prob = 0.5;
    [theory_real_state_2, theory_imag_state_2, theory_log_mag_state_2, theory_phase_state_2] = ...
    generate_bifurcated_s11_for_single_detuning_power(res_freq_GHz, detunings_MHz, input_power_at_sample_dBm, random_prob*ones(1,length(theory_probability)), kappa_int_MHz, kappa_ext_MHz, kerr_MHz);

end