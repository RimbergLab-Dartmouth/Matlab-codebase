function[err] = fit_2_gaussians_same_sigma_with_constraints_error_calc (variable_params, x_data, y_data, mean_constraint)
    
    if ~exist('mean_constraint', 'var')
        mean_constraint = 0;
    end

    gaussian_1_amp = variable_params(1);
    gaussian_2_amp = variable_params(4);
    gaussian_1_mean = variable_params(2);
    gaussian_2_mean = variable_params(5);
    gaussians_sigma = variable_params(3);
    
    if abs(gaussian_1_mean - gaussian_2_mean) < mean_constraint
        err = 1e15;
        return
    end
    
    gaussian_theory = gaussian_1_amp.*exp(-(x_data - gaussian_1_mean).^2/2./gaussians_sigma.^2) + gaussian_2_amp.*exp(-(x_data - gaussian_2_mean).^2/2./gaussians_sigma.^2);
    err = mean((gaussian_theory - y_data).^2);
    
end