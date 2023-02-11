function[clean_time_data, clean_RTS_amp_data, raw_data_out,gaussian_1_mean, gaussian_2_mean, sigma_double_gaussian, double_gaussian_error, area_gaussian_1, area_gaussian_2, lifetime_state_1, lifetime_state_2, ...
    lifetime_state_1_array, lifetime_state_2_array, threshold_1_array, threshold_2_array, theory_hist_phases, theory_gaussian_1, theory_gaussian_2, hist_axis, shifted_hist_data, single_gaussian_fit, ...
    single_theory_gaussian, single_gaussian_fit_error] = clean_RTS_signal_with_noise_broadening (time_data, RTS_amp_data, sigma_guess, bin_edges)
%%%% this code is based on Yuzhelevski Rev Sci instru 2000. Iteratively find lifetime values for state 1 and 2 and clean up the time series data at each iteration until the areas of the histogram at a given
%%%% iteration matches the area of the histogram of the raw data. Make sure RTS_amp_data is in degs
%%% time_data and RTS_amp_data need to be a 1D array of equal length
    
    min_phase_diff = 22; % this is the minimum difference the double gaussian fit looks for between the means  of the 2 Gaussians
    if length(time_data) ~= length(RTS_amp_data)
        disp('Input array dimensions must be the same')
        clean_time_data = time_data;
        clean_RTS_amp_data = RTS_amp_data;
        gaussian_1_mean = 0;
        gaussian_2_mean = 0;
        sigma_double_gaussian = 0;
        area_gaussian_1 = 0;
        area_gaussian_2 = 0;
        lifetime_state_1 = 0;
        lifetime_state_2 = 0;
        return 
    end

    sample_time_interval = mean(diff(time_data));
    
    %%%% if bin_edges was not specified in input to function, assume it is
    %%%% fitting a double gaussian to phases and use a bin width of 6 degs.
    if ~exist('sigma_guess', 'var')
        sigma_guess = 15;
    end
    if ~exist('bin_edges','var')
        bin_width = 6; 
        bin_edges = -180:bin_width: 180;
    else 
        bin_width = mean(diff(bin_edges));
    end
    
    %%% form a histogram of the collected data %%%%
    hist_data = histcounts(RTS_amp_data, bin_edges);
    
    %%%% identify peak of the collected data and move that to the middle to facilitate finding of peaks using findpeaks function 
    [~,I] = max(hist_data);
    peak_angle = bin_edges(I) + bin_width/2;
    bin_middles = bin_edges(1:end - 1) + bin_width/2;
    %%%% shift the peak phase into middle of array%%%%%
    shifted_bin_middles = circshift(bin_middles, floor(0.5*length(bin_middles)) - I);
    shifted_hist_data = circshift(hist_data, 1.5*length(bin_middles) - I);
    shifted_bin_middles_180 = shifted_bin_middles - shifted_bin_middles(length(shifted_bin_middles)/2);
    shifted_bin_middles_360 = shifted_bin_middles - shifted_bin_middles(length(shifted_bin_middles)/2) + 180;
    
    %%%% fit a double gaussian to the hist data %%%%
    [best_double_gaussian_fit_180, theory_double_gaussian_values_180, success_double_gaussian_fit_180, area_gaussian_left_180, area_gaussian_right_180, fit_error_180, ...
        theory_gaussian_1_values_180, theory_gaussian_2_values_180] = ...
        fit_2_gaussians_same_sigma_with_constraints(wrapTo180(shifted_bin_middles_180), shifted_hist_data, sigma_guess, min_phase_diff);

    [best_double_gaussian_fit_360, theory_double_gaussian_values_360, success_double_gaussian_fit_360, area_gaussian_left_360, area_gaussian_right_360, fit_error_360, ...
        theory_gaussian_1_values_360, theory_gaussian_2_values_360] = ...
        fit_2_gaussians_same_sigma_with_constraints(wrapTo360(shifted_bin_middles_360), shifted_hist_data, sigma_guess, min_phase_diff);

    %%%% fit single Gaussian to the histogram data
    [single_gaussian_fit, single_theory_gaussian, single_gaussian_fit_error] = fit_gaussian(wrapTo180(shifted_bin_middles_180), shifted_hist_data);
    
    if fit_error_180 < fit_error_360 || fit_error_180 == fit_error_360
        gaussian_1_mean = wrapTo180(best_double_gaussian_fit_180(2));
        gaussian_2_mean = wrapTo180(best_double_gaussian_fit_180(5));% + shifted_bin_middles(length(shifted_bin_middles)/2)) 
        hist_axis = wrapTo180(shifted_bin_middles_180);
        RTS_amp_data = wrapTo180(RTS_amp_data - shifted_bin_middles(length(shifted_bin_middles)/2));  % correct for the shift applied earlier to connect with original data
        sigma_double_gaussian = best_double_gaussian_fit_180(3);
        theory_gaussian_1 = theory_gaussian_1_values_180;
        theory_gaussian_2 = theory_gaussian_2_values_180;
        area_gaussian_1 = area_gaussian_left_180;
        area_gaussian_2 = area_gaussian_right_180;
        double_gaussian_error = fit_error_180;
    else 
        gaussian_1_mean = wrapTo360(best_double_gaussian_fit_360(2));  
        gaussian_2_mean = wrapTo360(best_double_gaussian_fit_360(5));
        hist_axis = wrapTo360(shifted_bin_middles_360);
        RTS_amp_data = wrapTo360(RTS_amp_data - shifted_bin_middles(length(shifted_bin_middles)/2) + 180);   % correct for the shift applied earlier to connect with original data
        sigma_double_gaussian = best_double_gaussian_fit_360(3);
        theory_gaussian_1 = theory_gaussian_1_values_360;
        theory_gaussian_2 = theory_gaussian_2_values_360;
        area_gaussian_1 = area_gaussian_left_360;
        area_gaussian_2 = area_gaussian_right_360;
        double_gaussian_error = fit_error_360;
    end
    
    area_ratio_1_to_2 = area_gaussian_1 / area_gaussian_2;
    raw_data_out = RTS_amp_data;
    if gaussian_2_mean < gaussian_1_mean
        temp = gaussian_1_mean; 
        gaussian_1_mean = gaussian_2_mean;
        gaussian_2_mean = temp;
        clear temp
    end

    difference_both_RTS_points = gaussian_2_mean - gaussian_1_mean;
    iteration_number = 1;
%     figure
%     bar(hist_axis, theory_gaussian_1)
%     hold on
%     bar(hist_axis, theory_gaussian_2)
    while iteration_number < 5 && ~single_gaussian_fit_error < double_gaussian_error
        if iteration_number == 1
            threshold_point_1 = gaussian_1_mean + difference_both_RTS_points/2;% + sigma_guassian^2/bin_width;
            threshold_point_2 = gaussian_2_mean - difference_both_RTS_points/2; %- sigma_gaussian^2/bin_width; 
            state_assignment = 2*ones(length(time_data),1);
            state_assignment(RTS_amp_data < threshold_point_1) = -1;
            state_assignment(RTS_amp_data > threshold_point_1) = 1;
            first_sure_state = 1;
        else
            clear phase_iteration_array_temp
            threshold_point_1 = gaussian_1_mean + difference_both_RTS_points/2 + sigma_double_gaussian^2/difference_both_RTS_points*log(lifetime_state_1/sample_time_interval - 1);
            threshold_point_2 = gaussian_2_mean - difference_both_RTS_points/2 - sigma_double_gaussian^2/difference_both_RTS_points*log(lifetime_state_2/sample_time_interval - 1);

            if iteration_number == 2
                state_assignment = 2*ones(length(time_data), 1);
                state_assignment(RTS_amp_data< gaussian_1_mean - 1.5*sigma_double_gaussian) = -1;
                state_assignment(RTS_amp_data > gaussian_2_mean + 1.5*sigma_double_gaussian) = 1;

                first_sure_state = find(state_assignment~=2, 1);
                fitting_times = time_data(first_sure_state:end);
                fitting_RTS_amps = RTS_amp_data(first_sure_state:end);
                state_assignment(1:first_sure_state - 1) = [];
            end
            for i = 2 : length(fitting_times)
%                 size(theory_gaussian_1)
%                 fitting_RTS_amps(i)
%                 find(abs(fitting_RTS_amps(i) - hist_axis) < bin_width, 1)
%                 bin_width
%                 hist_axis
                hist_value_corresponding_gaussian_1(i) = theory_gaussian_1(find(abs(fitting_RTS_amps(i) - hist_axis) < bin_width, 1));
                hist_value_corresponding_gaussian_2(i) = theory_gaussian_2(find(abs(fitting_RTS_amps(i) - hist_axis) < bin_width, 1));
                if state_assignment(i - 1) == -1
                    separator_ratio_value(i) = hist_value_corresponding_gaussian_2(i)/hist_value_corresponding_gaussian_1(i) *area_ratio_1_to_2 *sample_time_interval/(lifetime_state_1 - sample_time_interval);
                    if separator_ratio_value(i) < 1
                        state_assignment(i) = -1;
                    else
                        state_assignment(i) = 1;
                    end
                elseif state_assignment(i - 1) == 1
                    separator_ratio_value(i) = hist_value_corresponding_gaussian_1(i)/hist_value_corresponding_gaussian_2(i) /area_ratio_1_to_2 *sample_time_interval/(lifetime_state_2 - sample_time_interval);
                    if separator_ratio_value(i) < 1
                        state_assignment(i) = 1;
                    else
                        state_assignment(i) = -1;
                    end
                end                
            end 
        end
        state_change_array = diff(state_assignment);
        state_change_array(state_change_array == 0) = [];
        number_switches = length(state_change_array);
        if first_sure_state > size(state_assignment)
            run_broken = 1;
            break
        else 
            run_broken = 0;
        end
        if mod(number_switches, 2) == 1
            lifetime_state_1 = 2 * area_gaussian_1 * sample_time_interval / number_switches;
            lifetime_state_2 = 2 * area_gaussian_2 * sample_time_interval / number_switches;
        else 
            if state_assignment(first_sure_state) == -1 
                lifetime_state_1 = area_gaussian_1 * sample_time_interval/(number_switches/2 + 1);
                lifetime_state_2 = 2 * area_gaussian_2 * sample_time_interval/number_switches;
            else
                lifetime_state_1 = 2 * area_gaussian_1 * sample_time_interval/number_switches;
                lifetime_state_2 = area_gaussian_2 * sample_time_interval/(number_switches/2 + 1);
            end
        end
%         lifetime_state_1 = 10e-6;
%         lifetime_state_2 = 60e-6;
        error_lifetime_ratio(iteration_number) = abs(lifetime_state_1/lifetime_state_2 - area_gaussian_1/area_gaussian_2);
        threshold_1_array(iteration_number) = threshold_point_1;
        threshold_2_array(iteration_number) = threshold_point_2;
        clear phase_iteration_array_temp
        phase_iteration_array_temp (state_assignment == -1) = gaussian_1_mean;
        phase_iteration_array_temp(state_assignment == 1) = gaussian_2_mean;
        
        if gaussian_1_mean > gaussian_2_mean
            lifetime_state_1_array(iteration_number) = lifetime_state_1;
            lifetime_state_2_array(iteration_number) = lifetime_state_2;
        else
            lifetime_state_1_array(iteration_number) = lifetime_state_2;
            lifetime_state_2_array(iteration_number) = lifetime_state_1;
        end
%         size(phase_iteration_array_temp)
        phase_iteration_array(iteration_number, 1 : length(time_data)) = zeros(1, length(time_data));
%         size(phase_iteration_array)
        phase_iteration_array(iteration_number,1:first_sure_state - 1) = RTS_amp_data(1:first_sure_state - 1);
        phase_iteration_array(iteration_number, first_sure_state : end) = phase_iteration_array_temp;
        iteration_number = iteration_number + 1;
    end 
%     figure
%     plot(time_data, RTS_amp_data)
%     hold on
%     plot(clean_time_data, clean_RTS_amp_data(end,:))
    if single_gaussian_fit_error < double_gaussian_error || run_broken == 1
        clean_RTS_amp_data = zeros(length(time_data),1);
        error_lifetime_ratio = 0;
        lifetime_state_1 = 0;
        lifetime_state_2 = 0;
        lifetime_state_1_array = 0;
        lifetime_state_2_array = 0;
        threshold_1_array = 0;
        threshold_2_array = 0;
        phase_iteration_array = 0;
        clean_time_data = time_data;
        theory_hist_phases = hist_axis;
    else
        if fit_error_180 < fit_error_360
            clean_RTS_amp_data = wrapTo180(phase_iteration_array(end,:) + peak_angle);
%             mean(phase_iteration_array(end,:))
%             disp('wrapped 180')
            raw_data_out = wrapTo180(raw_data_out + peak_angle);
            clean_time_data = time_data;
            theory_hist_phases = wrapTo180(hist_axis + peak_angle);
        else            
            clean_RTS_amp_data = wrapTo360(phase_iteration_array(end,:) + peak_angle) - 180;
%             mean(phase_iteration_array(end,:))
%             disp('wrapped 360')
            raw_data_out = wrapTo360(raw_data_out + peak_angle) - 180;
            clean_time_data = time_data;
            theory_hist_phases = wrapTo360(hist_axis + peak_angle) - 180;
    end
end