function [best_fit,theory_values, success, area_gaussian_left, area_gaussian_right, fit_error, gaussian_1_theory, gaussian_2_theory] = ...
    fit_2_2d_gaussians_same_sigma_with_constraints(x_data,y_data, z_data, sigma_guess, mean_constraint)

    if ~exist('mean_constraint', 'var')
        mean_constraint = 0;
    end
    
    [~, x_peaks] = max(z_data, [], 1);
    [~, y_peaks] = max(z_data(x_peaks, :)