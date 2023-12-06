function[err]= transmission_q_circle_error_calc_with_angle(variable_params,data_real,data_imag,freq)
     freq_res_guess=variable_params(1);
     gamma_int_guess=variable_params(2);
     gamma_ext_guess=variable_params(3);
     angle_guess = variable_params(4);
%      angle_guess=variable_params(4);
%      data_phase=data_phase-mean_phase;
%      [data_real,data_imag]=rotate_data(data_real,data_imag,angle_guess*2*pi/360);
%      data_real=data_lin_mag.*cos(2*pi*data_phase/360);
%      data_imag=data_lin_mag.*sin(2*pi*data_phase/360);
     
%      if freq_res_guess>6e9
%          err=1e9;
%          disp('resonance too high')
%          return
%      end
     if gamma_int_guess<1e3
         err=1e9;
%          disp('gamma int too low')
         return
     end
     if gamma_int_guess>freq(end)-freq(1)
         err=1e9;
%          disp('gamma int too high')
         return
     end
     if gamma_ext_guess<1e3
         err=1e9;
%          disp('gamma ext too low')
         return
     end
     if gamma_ext_guess>freq(end)-freq(1)
         err=1e9;
%          disp('gamma ext too high')
         return
     end
     if freq_res_guess<min(freq)
         err=1e9;
%          disp('res freq too low')
         return
     end
     if freq_res_guess>max(freq)
         err=1e9;
%          disp('res freq too high')
         return
     end
%      if gamma_ext_guess<gamma_int_guess
%          err=1e9;
%          return
%      end
%      [data_real,data_imag]=rotate_data(data_real,data_imag,angle_guess);
%      data_real=data_real';
%      data_imag=data_imag';
     [theory_real, theory_imag]=transmission_q_circle_with_angle(freq,gamma_int_guess,gamma_ext_guess,freq_res_guess,angle_guess);
%      size(theory_real)
%      size(data_real)
%      size(theory_imag)
%      size(data_imag)
     err = mean(sqrt((theory_real-data_real).^2 + (theory_imag - data_imag).^2));
%      err=mean(abs(theory_real-data_real)+abs(theory_imag-data_imag));
end