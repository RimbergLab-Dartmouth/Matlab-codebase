function [expected_res_freq, theory_freq_shift] = res_freq_expected_for_Jules_sample(ng_value, flux_value)

    Ej= 14.8e9;
    Ec = 54.1e9;
    number_charge_states = 9;
    number_of_point_for_derivative = 6;
    Jules_sample_center_freq = 5.7575e9;

    flux_dummies = 2*pi*linspace(flux_value - 0.5, flux_value + 0.5, 31);
    gate_dummies = linspace(ng_value - 2, ng_value + 2, 31);
    [theory_freq_shift]=eigenvalues_v1_2_struct(Ej,Ec,number_charge_states,flux_dummies,gate_dummies,1,1,0,0,number_of_point_for_derivative);
    % 	[theory_freq_shift]=eigenvalues_v1_2(14.8e9,54.1e9,9,flux_dummies,gate_dummies,1,1,0,0,6);
    % 	[theory_freq_shift]=eigenvalues_v1_2(14.8e9,61e9,9,flux_dummies,gate_dummies,1,1,0,0,6);
    theory_freq_shift = theory_freq_shift(16, 16);
    expected_res_freq = theory_freq_shift + Jules_sample_center_freq;
    
end
