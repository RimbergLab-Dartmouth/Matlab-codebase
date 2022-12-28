function [model_out, best_fit,theory_values, fit_error, success]=fit_linear_cfit(x_data,y_data)
    %%%%% fits a linear %%%%
    
    success = 0;
    x_data = x_data(:);
    y_data = y_data(:);
    [~, y_intercept_guess_index] = min(abs(x_data));
    y_intercept_guess = y_data(y_intercept_guess_index);
    
    %%%% estimate slope
    slope_guess = (y_data(end) - y_data(1))/(x_data(end) - x_data(1));
    
    
    linear_theory= @(slope, intercept, x_data) slope*x_data + intercept; 
%     err= @(p) mean((sigmoid_theory(p,x_data)-y_data).^2);
%     options=optimset('MaxIter',50000,'MaxFunEvals',50000,'TolFun',1e-10,'TolX',1e-10);
%     [best_fit]=fminsearch(err,[delta_0_guess, gamma_guess],options);
    ft= fittype(linear_theory, 'indep', {'x_data'});
    model_out = fit(x_data, y_data, ft, 'start', [slope_guess, y_intercept_guess]);
    best_fit(1) = model_out.slope;
    best_fit(2) = model_out.intercept;
    theory_values = linear_theory(model_out.slope, model_out.intercept, x_data);
    fit_error = mean((theory_values - y_data).^2);
    success = 1;
end