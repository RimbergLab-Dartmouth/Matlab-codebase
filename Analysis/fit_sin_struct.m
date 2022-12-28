function [best_fit,theory_fit, goodness_fit]=fit_sin_struct(x_data,y_data)
    amp_guess=(max(y_data)-min(y_data))/2;
    offset_guess=mean(y_data);
    [~,IL]=mink(abs(y_data-offset_guess),4);
    [I,] = mink(IL,2);
    period_guess=abs((x_data(I(1))-x_data(I(2)))*2);
    phase_guess=2*pi*mod(x_data(I(1)),period_guess)/period_guess;
    if phase_guess > pi
        phase_guess = phase_guess - pi;
    end
    sin_theory= @(p,x_data) p(1)+p(2).*sin(2*pi*x_data./p(3)+p(4));
    err= @(p) mean(((sin_theory(p,x_data)-y_data).^2)/1e9);
     options=optimset('MaxIter',500000,'MaxFunEvals',500000,'TolFun',1e-14,'TolX',1e-14);
    [best_fit,goodness_fit]=fminsearch(err,[offset_guess, amp_guess, period_guess, phase_guess],options);
    offset_fit = best_fit(1);
    amplitude_fit = best_fit(2);
    period_fit = best_fit(3);
%     best_fit(4) = best_fit(4)*180/pi; % switch to degs
    phase_fit = best_fit(4)*180/pi;
    theory_fit = offset_fit + amplitude_fit.*sin(2*pi*x_data./period_fit + phase_fit*pi/180);
end