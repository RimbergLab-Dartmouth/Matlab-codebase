function [expected_res_freq, theory_freq_shift] = expected_res_freq_test(ng_value, flux_value)

    Ej= 14.8e9;
    Ec = 54.1e9;
    number_charge_states = 9;
    number_of_point_for_derivative = 6;
    center_freq = 5.7575e9;

    flux_dummies = 2*pi*linspace(flux_value - 0.5, flux_value + 0.5, 31);
    gate_dummies = linspace(ng_value - 2, ng_value + 2, 31);
    [theory_freq_shift]=eigenvalue_test(Ej,Ec,number_charge_states,flux_dummies,gate_dummies,number_of_point_for_derivative);
    theory_freq_shift = theory_freq_shift(16, 16);
    expected_res_freq = theory_freq_shift + center_freq;
    
end