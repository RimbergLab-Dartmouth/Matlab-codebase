function[err]=f_inverse_fitting_error_calc(variable_params,data_amps,freqs)
     amp_guess=variable_params(1);
     power_guess=variable_params(2);
     
%      if gamma_ext_guess<gamma_int_guess
%          err=1e9;
%          return
%      end
%      [data_real,data_imag]=rotate_data(data_real,data_imag,angle_guess);
%      data_real=data_real';
%      data_imag=data_imag';
     [~,theory_amps] = f_inverse_law(freqs,amp_guess,power_guess);
%      size(theory_real)
%      size(data_real)
%      size(theory_imag)
%      size(data_imag)
     err = mean(abs(data_amps - theory_amps));
%      err=mean(abs(theory_real-data_real)+abs(theory_imag-data_imag));
end