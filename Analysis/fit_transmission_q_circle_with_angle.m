function[fit_struct,flag,output]=...
    fit_transmission_q_circle_with_angle(data_log_mag,data_phase,freq_points,gamma_int_guess,gamma_ext_guess)
%     if ~exist('var','gamma_int_guess')
%         gamma_int_guess=2e6;
%     end
%     if ~exist('var','gamma_ext_guess')
%         gamma_ext_guess=5e6;
%     end
    [data_lin_mag,data_phase_radians]=extract_lin_mag_and_phase_radians(freq_points,data_log_mag,data_phase);
    [data_real,data_imag]=extract_real_imag(freq_points,data_lin_mag,data_phase_radians);
    err= @(p) transmission_q_circle_error_calc_with_angle(p,data_real,data_imag,freq_points);
    options=optimset('MaxIter',500000,'MaxFunEvals',500000,'TolFun',1e-14,'TolX',1e-14);
    [m,i]=min(data_log_mag);
    freq_res_guess=freq_points(i);
    angle_guess = 7;
%     angle_guess = 0;
    initial_params=[freq_res_guess,gamma_int_guess,gamma_ext_guess,angle_guess];
    [fit_params_temp,goodness_fit,flag,output]=fminsearch(err,initial_params,options);
    freq_res_fit=fit_params_temp(1);
    gamma_int_fit=fit_params_temp(2);
    gamma_ext_fit=fit_params_temp(3);
    angle_fit = fit_params_temp(4);
%     angle_fit=fit_params_temp(4);
%     disp(['final error is ' num2str(goodness_fit)]);
    [theory_real,theory_imag] = transmission_q_circle_with_angle(freq_points,gamma_int_fit,gamma_ext_fit,freq_res_fit,angle_fit);%     plot(theory_real,theory_imag,'r')
%     hold on
    [data_lin_mag,data_phase_radians]=extract_lin_mag_and_phase_radians(freq_points,data_log_mag,data_phase);
    [data_real,data_imag]=extract_real_imag(freq_points,data_lin_mag,data_phase_radians);
    fit_struct.goodness_fit = goodness_fit;
    fit_struct.res_freq_fit = freq_res_fit;
    fit_struct.gamma_int_fit = gamma_int_fit;
    fit_struct.gamma_ext_fit = gamma_ext_fit;
    fit_struct.angle_fit = angle_fit;
    fit_struct.data_real = data_real;
    fit_struct.data_imag = data_imag;
    fit_struct.theory_real = theory_real;
    fit_struct.theory_imag = theory_imag;
%     scatter(data_real,data_imag,'b')
end