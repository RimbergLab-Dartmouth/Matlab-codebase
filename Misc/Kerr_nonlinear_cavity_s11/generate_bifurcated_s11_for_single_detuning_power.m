function[theory_real, theory_imag, theory_log_mag, theory_phase] = ...
    generate_bifurcated_s11_kerr_flucs_for_single_detuning_power(res_freq_GHz, detuning_MHz, input_power_at_sample_dBm, prob_at_detuning, kappa_int_MHz, kappa_ext_MHz, kerr_MHz)
%%%% it can in principle handle multiple values, but for fitting purposes, use one at a time
    
    h = 6.626e-34;
    kappa_tot_MHz = kappa_int_MHz + kappa_ext_MHz;
    power_input_watts = 1e-3.*10.^(input_power_at_sample_dBm/10);
    power_input_in_numbers = power_input_watts/h/res_freq_GHz/1e9;
    power_input_in_numbers = power_input_in_numbers/1e6;
    [detunings_array, power_input_array] = meshgrid(detuning_MHz, power_input_in_numbers);
    amp_roots = zeros([size(detunings_array), 3]);
    
    for i = 1: size(detunings_array,1)
        for j = 1: size(detunings_array,2)
            amp_roots(i,j,:) = roots([kerr_MHz^2, -2*kerr_MHz.*detunings_array(i,j), (detunings_array(i,j).^2 + kappa_tot_MHz^2 / 4),...
                -kappa_ext_MHz * power_input_array(i,j)]);
        end
    end
    
    amp_roots(imag(amp_roots) ~=0) = 0;
    main_s11_forward = zeros([size(detunings_array)]);
    main_s11_reverse = zeros([size(detunings_array)]);
    main_s11_forward_power = zeros([size(detunings_array)]);
    main_s11_reverse_power = zeros([size(detunings_array)]);
    first_zero_root_1 = zeros(size(detunings_array,1),1);
    first_zero_root_3 = zeros(size(detunings_array,1),1);
    
    detunings_array_reps = repmat(detunings_array, [1, 1, 3]);
    s11 = ((detunings_array_reps - kerr_MHz .* amp_roots) - 1i*(kappa_tot_MHz -...
    2*kappa_ext_MHz)/2)./((detunings_array_reps - kerr_MHz .* amp_roots) -1i*kappa_tot_MHz/2);
    s11(amp_roots == 0) = 5;
    for i = 1: size(detunings_array,1)
        number_zeros_1 = sum(double(amp_roots(i,:,1) == 0));
        number_zeros_3 = sum(double(amp_roots(i,:,3) == 0));
        if number_zeros_1 > 0 && number_zeros_3 > 0
            first_zero_root_3(i) = find(amp_roots(i,:,3) == 0, 1) - 1;
            first_zero_root_1(i) = length(amp_roots(i,:,1)) - find(flip(amp_roots(i,:,1) ~= 0),1) + 1;
            main_s11_reverse_temp = s11(i,:,1);
            s11_3_temp = s11(i,:,3);
            zero_entries = (main_s11_reverse_temp == 5);
            main_s11_reverse_temp(zero_entries) = s11_3_temp(zero_entries);
            main_s11_forward(i,:) = [s11(i,1:first_zero_root_3(i),3), s11(i,first_zero_root_3(i) + 1: first_zero_root_1(i), 1), s11(i,first_zero_root_1(i) + 1: end, 3)]; 
            main_s11_reverse(i,:) = main_s11_reverse_temp;
        else 
            main_s11_forward = s11(:,:,3);
            main_s11_reverse = s11(:,:,3);
        end
    end
    for i = 1: size(power_input_array,2)
        number_zeros_1 = sum(double(amp_roots(:,i,1) == 0));
        number_zeros_3 = sum(double(amp_roots(:,i,3) == 0));
        if number_zeros_1 > 0 && number_zeros_3 > 0
            first_zero_root_3(i) = find(amp_roots(:,i,3) == 0, 1) - 1;
            first_zero_root_1(i) = length(amp_roots(:,i,1)) - find(flip(amp_roots(:,i,1) ~= 0),1) + 1;
            main_s11_reverse_temp_power = s11(:,i,1);
            s11_3_temp = s11(:,i,3);
            zero_entries = (main_s11_reverse_temp_power == 5);
            main_s11_reverse_temp_power(zero_entries) = s11_3_temp(zero_entries);
            main_s11_forward_power(:,i) = [s11(1:first_zero_root_3(i),i,3); s11(first_zero_root_3(i) + 1: end,i, 1)];         
            main_s11_reverse_power(:,i) = main_s11_reverse_temp_power;
        end
    end
    
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

    s11_averaged = squeeze(sum(probability_array.*s11,3));
    theory_real = real(s11_averaged);
    theory_imag = imag(s11_averaged);
    theory_log_mag = 20*log10(abs(s11_averaged));
    theory_phase = wrapTo180(angle(s11_averaged));
    
    
end