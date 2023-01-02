function [lifetime_state_1, lifetime_state_2, amplitude_difference_states, theory_lorentzian, fit_error] = fit_RTS_lorentzian(freqs, psd, guess_lifetime_1, guess_lifetime_2, guess_difference)
    
    guess_params = [guess_difference, guess_lifetime_1, guess_lifetime_2];

    lorentzian_theory = @(p, freqs) 4*p(1)^2 *(p(3)*p(2))^2/(p(3) + p(2))^3 ./ (1 + 4*pi^2.*freqs.^2/(1/p(2) + 1/p(3))^2);
    err = @(p) mean((lorentzian_theory(p, freqs) - psd).^2);
    options = optimset('MaxIter', 50000, 'MaxFunEvals', 50000, 'TolFun', 1e-10, 'TolX', 1e-10);
    [best_fit, fit_error] = fminsearch(err, guess_params, options);

    amplitude_difference_states = best_fit(1);
    lifetime_state_1 = best_fit(2);
    lifetime_state_2 = best_fit(3);
    
    theory_lorentzian = 4*best_fit(1)^2 * (best_fit(3) * best_fit(2))^2/(best_fit(3) + best_fit(2))^3 ./ (1 + 4*pi^2 .* freqs.^2/(1/best_fit(2) + 1/best_fit(3))^2);
end