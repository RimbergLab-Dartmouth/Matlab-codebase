function [best_fit,theory_values, success, area_gaussian_left, area_gaussian_right, fit_error, gaussian_1_theory, gaussian_2_theory]=fit_2_gaussians_same_sigma(x_data,y_data, sigma_guess)
    
%%%%% find peaks, but ignoring really small peaks on the tails %%%%%
    y_data_find_peaks = y_data;
    y_data_find_peaks(y_data_find_peaks < max(y_data)/10) = 0;
    [pks, locs] = findpeaks(y_data_find_peaks, 'SortStr', 'descend');
    
    if length(pks) == 1
        pks(2) = pks(1);
        locs(2) = locs(1);
    end
    
    pks = pks(1:2);
    locs = locs(1:2);
    
    amp_guess_1 = pks(1);
    amp_guess_2 = pks(2);
    mean_guess_1 = x_data(locs(1));
    mean_guess_2 = x_data(locs(2));
%%%%%%%%
    
%     [~,fwhm_indices_1] = mink(abs(y_data - amp_guess_1/2), 4);
%     fwhm_left_1 = fwhm_indices_1(1);
%     if (x_data(fwhm_indices_1(1)) - mean_guess_1) * (x_data(fwhm_indices_1(2)) - mean_guess_1) < 0
%         fwhm_right_1 = fwhm_indices_1(2);
%     elseif (x_data(fwhm_indices_1(1)) - mean_guess_1) * (x_data(fwhm_indices_1(3)) - mean_guess_1) < 0
%         fwhm_right_1 = fwhm_indices_1(3);
%     elseif (x_data(fwhm_indices_1(1)) - mean_guess_1) * (x_data(fwhm_indices_1(3)) - mean_guess_1) < 0
%         fwhm_right_1 = fwhm_indices_1(4);
%     else
% %         disp('could not find a sigma guess')
%         success = 0;
%         best_fit= zeros(1,3);
%         theory_values = zeros(size(x_data));
%         return
%     end
%     sigma_guess = abs(x_data(fwhm_left_1) - x_data(fwhm_right));

    gaussian_theory= @(p,x_data) p(1).*exp(-(x_data - p(2)).^2/2./p(3).^2) + p(4).*exp(-(x_data - p(5)).^2/2./p(3).^2);
    err= @(p) mean((gaussian_theory(p,x_data)-y_data).^2);
    options=optimset('MaxIter',50000,'MaxFunEvals',50000,'TolFun',1e-10,'TolX',1e-10);
    [best_fit, fit_error]=fminsearch(err,[amp_guess_1,mean_guess_1, sigma_guess, amp_guess_2, mean_guess_2],options);
%     theory_values = best_fit(1).*exp(-(x_data - best_fit(2)).^2/2./best_fit(3).^2) + best_fit(4).*exp(-(x_data - best_fit(5)).^2/2./best_fit(3).^2);
    gaussian_1_theory = best_fit(1) .*exp(-(x_data - best_fit(2)).^2/2./best_fit(3).^2);
    gaussian_2_theory = best_fit(4).*exp(-(x_data - best_fit(5)).^2/2./best_fit(3).^2);
    theory_values = gaussian_1_theory + gaussian_2_theory;
    if any(x_data<0)
%         if wrapTo180(best_fit(2)) < wrapTo180(best_fit(5)) 
%             area_gaussian_left = sum(best_fit(1).*exp(-(x_data - best_fit(2)).^2/2./best_fit(3).^2));
%             area_gaussian_right = sum(best_fit(4).*exp(-(x_data - best_fit(5)).^2/2./best_fit(3).^2));
%         elseif wrapTo180(best_fit(2)) > wrapTo180(best_fit(5))
%             area_gaussian_right = sum(best_fit(1).*exp(-(x_data - best_fit(2)).^2/2./best_fit(3).^2));
%             area_gaussian_left = sum(best_fit(4).*exp(-(x_data - best_fit(5)).^2/2./best_fit(3).^2));
%         end
        if best_fit(2) < best_fit(5)
            area_gaussian_left = sum(best_fit(1).*exp(-(x_data - best_fit(2)).^2/2./best_fit(3).^2));
            area_gaussian_right = sum(best_fit(4).*exp(-(x_data - best_fit(5)).^2/2./best_fit(3).^2));
        elseif wrapTo180(best_fit(2)) > wrapTo180(best_fit(5))
            area_gaussian_right = sum(best_fit(1).*exp(-(x_data - best_fit(2)).^2/2./best_fit(3).^2));
            area_gaussian_left = sum(best_fit(4).*exp(-(x_data - best_fit(5)).^2/2./best_fit(3).^2));
        else 
            area_gaussian_right = 1;
            area_gaussian_left = 1;
        end
    else
         if wrapTo360(best_fit(2)) < wrapTo360(best_fit(5)) 
            area_gaussian_left = sum(best_fit(1).*exp(-(x_data - best_fit(2)).^2/2./best_fit(3).^2));
            area_gaussian_right = sum(best_fit(4).*exp(-(x_data - best_fit(5)).^2/2./best_fit(3).^2));
        elseif wrapTo360(best_fit(2)) > wrapTo360(best_fit(5))
            area_gaussian_right = sum(best_fit(1).*exp(-(x_data - best_fit(2)).^2/2./best_fit(3).^2));
            area_gaussian_left = sum(best_fit(4).*exp(-(x_data - best_fit(5)).^2/2./best_fit(3).^2));
        else 
            area_gaussian_right = 1;
            area_gaussian_left = 1;
         end
    end
    success = 1;
end