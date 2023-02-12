function[theory_real, theory_imag, theory_log_mag, theory_phase, probability_array] = ...
    generate_bifurcated_s11_kerr_flucs_for_single_detuning_power(res_freq_GHz, detuning_MHz, input_power_at_sample_dBm, prob_at_detuning, kappa_int_MHz, kappa_ext_MHz, kerr_MHz)
%%%% it can in principle handle multiple values, but for fitting purposes, use one at a time
    
    h = 6.626e-34;
    kappa_tot_MHz = kappa_int_MHz + kappa_ext_MHz;
    power_input_watts = 1e-3.*10.^(input_power_at_sample_dBm/10);
    power_input_in_numbers = power_input_watts/h/res_freq_GHz/1e9;
    power_input_in_numbers = power_input_in_numbers/1e6;
    [detunings_array, power_input_array] = meshgrid(detuning_MHz, power_input_in_numbers);
    amp_roots = zeros([size(detunings_array), 3]);
    
    kerr_fluctuation_detuning = linspace(-10*abs(kerr_MHz), 10*abs(kerr_MHz), 401);
    kerr_fluctuation_spacing = mean(diff(kerr_fluctuation_detuning));
    
    for i = 1: size(detunings_array,1)
        for j = 1: size(detunings_array,2)
            amp_roots(i,j,:) = roots([kerr_MHz^2, -2*kerr_MHz.*detunings_array(i,j), (detunings_array(i,j).^2 + kappa_tot_MHz^2 / 4),...
                -kappa_ext_MHz * power_input_array(i,j)]);
        end
    end
    
    amp_roots(imag(amp_roots) ~=0) = 0;
    
    probability_array = repmat(prob_at_detuning, size(detunings_array, 1), 1);
    probability_array = repmat(probability_array, 1, 1, 3);
    probability_array(:,:,3) = 1 - probability_array(:,:,3);
    probability_array(:,:,2) = 0;
    probability_array(amp_roots == 0) = 0;
    probability_array_sum = sum(probability_array, 3);
    probability_array_sum = repmat(probability_array_sum, 1, 1,3);
    probability_array(probability_array >0 & probability_array_sum <1) = 1;
    probability_array(probability_array >0 & probability_array_sum < 1) = 1;
    probability_array_sum = sum(probability_array,3);
    for i = 1: size(probability_array_sum,2)
        if probability_array_sum(1,i,1) == 0
            probability_array(1,i,3) = 1;
        end
    end

    
    detunings_array_reps = repmat(detunings_array, [1, 1, 3]);
    s11 = ((detunings_array_reps - kerr_MHz .* amp_roots) - 1i*(kappa_tot_MHz -...
    2*kappa_ext_MHz)/2)./((detunings_array_reps - kerr_MHz .* amp_roots) -1i*kappa_tot_MHz/2);
    s11(amp_roots == 0) = NaN;
    
    amp_roots = repmat(amp_roots, [1, 1, 1, length(kerr_fluctuation_detuning)]);
    s11 = repmat(s11, [1, 1, 1, length(kerr_fluctuation_detuning)]);
    kerr_fluctuation_detuning = repmat(kerr_fluctuation_detuning', [1, size(detunings_array_reps)]);
    kerr_fluctuation_detuning = permute(kerr_fluctuation_detuning, [2 3 4 1]);

    %%%%%% using eqn. 25 in Brock Phys Rev Applied 2020
    prob_chi_squared = 2/abs(kerr_MHz) * exp(-(2*amp_roots + 2*kerr_fluctuation_detuning/kerr_MHz)).* ...
        besseli(0, 4*sqrt(kerr_fluctuation_detuning.*amp_roots/kerr_MHz)).*heaviside(kerr_fluctuation_detuning/kerr_MHz);

    s11(isnan(s11)) = 0;
    kerr_averaged_s11 = sum(s11.*prob_chi_squared, 4) *kerr_fluctuation_spacing;
    s11(s11 == 0) = NaN;
    
    s11_averaged = squeeze(sum(probability_array.*kerr_averaged_s11,3));
    theory_real = real(s11_averaged);
    theory_imag = imag(s11_averaged);
    theory_log_mag = 20*log10(abs(s11_averaged));
    theory_phase = wrapTo180(180/pi*angle(s11_averaged));
    
    
end