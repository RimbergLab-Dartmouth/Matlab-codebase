function [best_fit,theory_values, success]=fit_gaussian(x_data,y_data)
    [amp_guess, mean_guess_index] = max(y_data);
    mean_guess = x_data(mean_guess_index);
    [~,fwhm_indices] = mink(abs(y_data - amp_guess/2), 4);
    fwhm_left = fwhm_indices(1);
    if (x_data(fwhm_indices(1)) - mean_guess) * (x_data(fwhm_indices(2)) - mean_guess) < 0
        fwhm_right = fwhm_indices(2);
    elseif (x_data(fwhm_indices(1)) - mean_guess) * (x_data(fwhm_indices(3)) - mean_guess) < 0
        fwhm_right = fwhm_indices(3);
    elseif (x_data(fwhm_indices(1)) - mean_guess) * (x_data(fwhm_indices(3)) - mean_guess) < 0
        fwhm_right = fwhm_indices(4);
    else
%         disp('could not find a sigma guess')
        success = 0;
        best_fit= zeros(1,3);
        theory_values = zeros(size(x_data));
        return
    end
    sigma_guess = abs(x_data(fwhm_left) - x_data(fwhm_right));
    gaussian_theory= @(p,x_data) p(1).*exp(-(x_data - p(2)).^2/2./p(3).^2);
    err= @(p) mean((gaussian_theory(p,x_data)-y_data).^2);
    options=optimset('MaxIter',50000,'MaxFunEvals',50000,'TolFun',1e-10,'TolX',1e-10);
    [best_fit]=fminsearch(err,[amp_guess,mean_guess, sigma_guess],options);
    theory_values = best_fit(1).*exp(-(x_data - best_fit(2)).^2/2./best_fit(3).^2);
    success = 1;
end