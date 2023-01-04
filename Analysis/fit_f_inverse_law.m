function[goodness_fit,amp_fit,exponent_fit,theory_freqs,theory_amps,flag,output]=...
    fit_f_inverse_law(data_freqs,data_amps)
%     if ~exist('var','gamma_int_guess')
%         gamma_int_guess=2e6;
%     end
%     if ~exist('var','gamma_ext_guess')
%         gamma_ext_guess=5e6;
%     end
    err= @(p) f_inverse_fitting_error_calc(p,data_amps,data_freqs);
    options=optimset('MaxIter',500000,'MaxFunEvals',500000,'TolFun',1e-16,'TolX',1e-16);
    initial_params=[max(data_amps),1.4];%initial power guess is (-)1.4
    [fit_params_temp,goodness_fit,flag,output]=fminsearch(err,initial_params,options);
    amp_fit=fit_params_temp(1);
    exponent_fit=fit_params_temp(2);
    [theory_freqs,theory_amps]=f_inverse_law(data_freqs,amp_fit,exponent_fit);
end