% detunings = linspace(-15, 15, 201);
% interpolated_probability = interp1(detunings_array, probability_best_180_360, detunings);
prob_test = interpolated_probability;
j = 69;
prob_test(j) = .03;
j = 75;
prob_test(j) = .035;
j = 85; 
prob_test(j) = .1;
for i = 1 : length(detunings)
    [theory_real(i), theory_imag(i), theory_log_mag(i), theory_phase(i)] = ...
    generate_bifurcated_s11_for_single_detuning_power(5.784, detunings(i), -129, prob_test(i), 1.238, .8873, -.22);
    if i == j
        disp(['theory point is ' num2str(theory_real(i) + 1i*theory_imag(i))])
        disp(['data point is ' num2str(data_real_with_flucs(i) + 1i*data_imag_with_flucs(i))])
        disp(['prob at point is ' num2str(prob_test(i))])
    end
end
% figure
% plot(detuning_array, probability_best_180_360, 'x')
% hold on
% plot(detunings, interpolated_probability)
figure
plot(theory_real, theory_imag, 'x')
hold on
plot(data_real_with_flucs, data_imag_with_flucs, 'o')
