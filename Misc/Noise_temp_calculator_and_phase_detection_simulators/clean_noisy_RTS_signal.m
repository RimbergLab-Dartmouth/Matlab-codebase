%% Function Clean RTS from noisy data
function [clean_time_data, raw_data_out, clean_RTS_data, gaussian_1_mean, gaussian_2_mean, sigma_double_gaussian, double_gaussian_fit_error, area_gaussian_1, area_gaussian_2, ...
    lifetime_state_1_final_iteration, lifetime_state_2_final_iteration, lifetime_state_1_iteration_array, lifetime_state_2_iteration_array, simple_threshold_clean_RTS_data, ...
    simple_threshold_lifetime_state_1, simple_threshold_lifetime_state_2, threshold_1_iteration_array, threshold_2_iteration_array, number_switches_both_states_iteration_array, ...
    number_switches_both_states_final_iteration, gaussian_1_theory_values, gaussian_2_theory_values, ...
    hist_RTS_bins, hist_count_data, single_gaussian_fit_params, single_gaussian_theory_values, single_gaussian_fit_error] = ...
    clean_noisy_RTS_signal(time_data, RTS_data, min_phase_diff_between_2_gaussian_centers, number_iterations, hist_bin_edges, gaussian_sigma_guess)
%%%% this code is based on Yuzhelevski Rev Sci instru 2000. Iteratively find lifetime values for state 1 and 2 and clean up the time series data at each iteration until the 
%%%% areas of the histogram at a given iteration matches the area of the histogram of the raw data. 

    if length(time_data) ~= length(RTS_data)
        disp('Input array dimensions do not match')
        clean_time_data = time_data;
        clean_RTS_data = RTS_data;
        gaussian_1_mean = 0;
        gaussian_2_mean = 0;
        sigma_double_gaussian = 0;
        double_gaussian_fit_error = 1e9;
        area_gaussian_1 = 1e9;
        area_gaussian_2 = 1e9;
        lifetime_state_1_final_iteration = 0;
        lifetime_state_2_final_iteration = 0;
        return
    end
    
    if ~exist('gaussian_sigma_guess', 'var')
        gaussian_sigma_guess = 15;
    end
    if ~exist('hist_bin_edges', 'var')
        hist_bin_width = 6; % degs
        hist_bin_edges = -180: hist_bin_width : 180;
    else
        hist_bin_width = mean(diff(hist_bin_edges));
    end
    if ~exist('number_iterations', 'var')
        number_iterations = 5;
    end
    
    sample_time_interval = mean(diff(time_data), 'omitnan');
    
    %%%% form a histogram of the RTS data %%%%
    hist_count_data = histcounts(RTS_data, hist_bin_edges);
    
    %%%% identify the peak of the histogram and move that to the middle 
    %%%% (phase = 0), to facilitate peak finding using findpeaks (in fit 2
    %%%% gaussian function)
    [~, I] = max(hist_count_data);
    peak_angle = hist_bin_edges(I) + hist_bin_width/2;
    hist_bin_middles = hist_bin_edges(1 : end - 1) + hist_bin_width/2;
    %%%%% shift the peak data point to middle of array
    hist_bin_middles = circshift(hist_bin_middles, floor(0.5*length(hist_bin_middles)) - I);
    hist_count_data = circshift(hist_count_data, floor(1.5*length(hist_bin_middles)) - I);
    clear I
    hist_bin_middles_wrapped_180 = hist_bin_middles - hist_bin_middles(length(hist_bin_middles)/2);
    hist_bin_middles_wrapped_360 = hist_bin_middles - hist_bin_middles(length(hist_bin_middles)/2) + 180;
    
    %%%%% fit double gaussian to the histograms
    [double_gaussian_fit_180, ~, ~, area_gaussian_left_180, area_gaussian_right_180, fit_error_180, theory_gaussian_1_values_180, theory_gaussian_2_values_180] = ...
            fit_2_gaussians_same_sigma_with_constraints(wrapTo180(hist_bin_middles_wrapped_180), hist_count_data, gaussian_sigma_guess, min_phase_diff_between_2_gaussian_centers);

    [double_gaussian_fit_360, ~, ~, area_gaussian_left_360, area_gaussian_right_360, fit_error_360, theory_gaussian_1_values_360, theory_gaussian_2_values_360] = ...
            fit_2_gaussians_same_sigma_with_constraints(wrapTo360(hist_bin_middles_wrapped_360), hist_count_data, gaussian_sigma_guess, min_phase_diff_between_2_gaussian_centers);        

    %%%%% fit single gaussian to the histograms
    [single_gaussian_fit_params, single_gaussian_theory_values, single_gaussian_fit_error] = fit_gaussian(wrapTo180(hist_bin_middles_wrapped_180), hist_count_data);
    
    if fit_error_180 < fit_error_360 || fit_error_180 == fit_error_360
        gaussian_1_mean = wrapTo180(double_gaussian_fit_180(2));
        gaussian_2_mean = wrapTo180(double_gaussian_fit_180(5));
        RTS_data = wrapTo180(RTS_data - hist_bin_middles(length(hist_bin_middles)/2));
        hist_bin_middles = wrapTo180(hist_bin_middles_wrapped_180);        
        %%%% correct for shift applied earlier, to connect raw data to cleaned data
        sigma_double_gaussian = double_gaussian_fit_180(3);
        gaussian_1_theory_values = theory_gaussian_1_values_180;
        gaussian_2_theory_values = theory_gaussian_2_values_180;
        area_gaussian_1 = area_gaussian_left_180;
        area_gaussian_2 = area_gaussian_right_180;
        double_gaussian_fit_error = fit_error_180;
    else
        gaussian_1_mean = wrapTo360(double_gaussian_fit_360(2));
        gaussian_2_mean = wrapTo360(double_gaussian_fit_360(5));        
        RTS_data = wrapTo360(RTS_data - hist_bin_middles(length(hist_bin_middles)/2) + 180);
        hist_bin_middles = wrapTo360(hist_bin_middles_wrapped_360);
        %%%% correct for shift applied earlier, to connect raw data to cleaned data
        sigma_double_gaussian = double_gaussian_fit_360(3);
        gaussian_1_theory_values = theory_gaussian_1_values_360;
        gaussian_2_theory_values = theory_gaussian_2_values_360;
        area_gaussian_1 = area_gaussian_left_360;
        area_gaussian_2 = area_gaussian_right_360; 
        double_gaussian_fit_error = fit_error_360;
    end
    
    area_ratio_gaussian_1_to_2 = area_gaussian_1/ area_gaussian_2;
    raw_data_out = RTS_data;
    %%%% ensure left gaussian is always to the left of right gaussian. the
    %%%% double gaussian fit just randomly spits that out
    if gaussian_2_mean < gaussian_1_mean
        temp = gaussian_1_mean;
        gaussian_1_mean = gaussian_2_mean;
        gaussian_2_mean = temp;
        clear temp
    end
    
    difference_gaussian_means = gaussian_2_mean - gaussian_1_mean;
    
    iteration_number = 1;
    %%%% start iteration to clean RTS
    while iteration_number < number_iterations + 1 && ~single_gaussian_fit_error < double_gaussian_fit_error
        %%%%% if just the first iteration, use threshold value right in the
        %%%%% middle of two gaussian peaks
        if iteration_number == 1
            threshold_point_1 = gaussian_1_mean + difference_gaussian_means/2;
            threshold_point_2 = gaussian_2_mean - difference_gaussian_means/2;
            state_assignment = 2*ones(length(time_data), 1);
            state_assignment(RTS_data < threshold_point_1)  = -1;
            state_assignment(RTS_data > threshold_point_1) = 1;
            first_sure_state = 1; % first time point where phase can be assigned to +/-1 with full confidence
            simple_threshold_clean_RTS_data = state_assignment;
            simple_threshold_clean_RTS_data(simple_threshold_clean_RTS_data == -1) = gaussian_1_mean;
            simple_threshold_clean_RTS_data(simple_threshold_clean_RTS_data == 1) = gaussian_2_mean;
            simple_threshold_number_changes = diff(simple_threshold_clean_RTS_data);
            simple_threshold_number_changes(simple_threshold_number_changes == 0) = [];
            simple_threshold_number_changes = length(simple_threshold_number_changes);
            if mod(simple_threshold_number_changes, 2) == 1
                simple_threshold_lifetime_state_1 = 2 * area_gaussian_1 * sample_time_interval/simple_threshold_number_changes;
                simple_threshold_lifetime_state_2 = 2 * area_gaussian_2 * sample_time_interval/simple_threshold_number_changes;
            else
                if state_assignment(1) == 1
                    simple_threshold_lifetime_state_1 = 2 * area_gaussian_1 * sample_time_interval/simple_threshold_number_changes;
                    simple_threshold_lifetime_state_2 = area_gaussian_2 * sample_time_interval/(simple_threshold_number_changes / 2 + 1);
                else
                    simple_threshold_lifetime_state_1 = area_gaussian_1 *sample_time_interval/(simple_threshold_number_changes / 2 + 1);
                    simple_threshold_lifetime_state_2 = 2 * area_gaussian_2 * sample_time_interval/ simple_threshold_number_changes;
                end
            end
            else
            %%%% calculate threshold points for this iteration number
            clear phase_iteration_array_temp
            threshold_point_1 = gaussian_1_mean + difference_gaussian_means/2 + sigma_double_gaussian^2/difference_gaussian_means*log(lifetime_state_1_current/sample_time_interval - 1);
            threshold_point_2 = gaussian_2_mean - difference_gaussian_means/2 - sigma_double_gaussian^2/difference_gaussian_means*log(lifetime_state_2_current/sample_time_interval - 1);
            
            if iteration_number == 2
                state_assignment = 2*ones(length(time_data), 1);
                %%%% finding states which are a good standard deviation
                %%%% away from mean values, we assign states +/- 1 to just
                %%%% these states for now.
                state_assignment(RTS_data < gaussian_1_mean - 1.5*sigma_double_gaussian) = -1;
                state_assignment(RTS_data < gaussian_2_mean + 1.5*sigma_double_gaussian) = 1;
                first_sure_state = find(state_assignment ~=2, 1); % find first state that is confidently assigned a state value
                fitting_times = time_data(first_sure_state:end); % the cleaning process only happens for time points after this first sure state
                fitting_RTS = RTS_data(first_sure_state:end);
                state_assignment(1 :first_sure_state - 1) = [];
            end
            %%%% starting with first sure state, go through each phase data
            %%%% point and assign a +/-1 state.
            for m_data_count = 2 : length(fitting_times)
                %%% find the histogram bin in which the current phase data falls. this will tell us what the probability 
                %%% for that phase value to occur is
                hist_value_corresponding_gaussian_1 (m_data_count) = gaussian_1_theory_values(find(abs(fitting_RTS(m_data_count) - hist_bin_middles) < hist_bin_width, 1));
                hist_value_corresponding_gaussian_2 (m_data_count) = gaussian_2_theory_values(find(abs(fitting_RTS(m_data_count) - hist_bin_middles) < hist_bin_width, 1));
                if state_assignment(m_data_count - 1) == -1
                    separator_ratio_value(m_data_count) = hist_value_corresponding_gaussian_2(m_data_count)/hist_value_corresponding_gaussian_1(m_data_count)* ...
                        area_ratio_gaussian_1_to_2 * sample_time_interval/(lifetime_state_1_current - sample_time_interval);
                    %%%% based on the above threshold and given the time since the last switch, assign state (eqns. (21
                    %%%% -26))
                    if separator_ratio_value(m_data_count) < 1
                        state_assignment(m_data_count) = -1;
                    else 
                        state_assignment(m_data_count) = 1;
                    end
                elseif state_assignment(m_data_count - 1) == 1
                    separator_ratio_value(m_data_count) = hist_value_corresponding_gaussian_1(m_data_count)/hist_value_corresponding_gaussian_2(m_data_count) ...
                        / area_ratio_gaussian_1_to_2 *sample_time_interval/(lifetime_state_2_current - sample_time_interval);
                    if separator_ratio_value(m_data_count) < 1
                        state_assignment(m_data_count) = 1;
                    else
                        state_assignment(m_data_count) = -1;
                    end
                end
            end
        end
        state_transition_array = diff(state_assignment);
        state_transition_array(state_transition_array == 0) = [];
        number_switches = length(state_transition_array);
        
        if first_sure_state > size(state_assignment)
            run_broken = 1;
            break
        else
            run_broken = 0;
        end
        %%%% calculate lifetimes based on Yuzhelevski 2000 Rev Sci Instru
        %%%% paper, eqn. (19) and (20)
        if mod(number_switches, 2) == 1
            lifetime_state_1_current = 2 * area_gaussian_1 * sample_time_interval/number_switches;
            lifetime_state_2_current = 2 * area_gaussian_2 * sample_time_interval/number_switches;
        else
            if state_assignment(first_sure_state) == 1
                lifetime_state_1_current = 2 * area_gaussian_1 * sample_time_interval/number_switches;
                lifetime_state_2_current = area_gaussian_2 * sample_time_interval/(number_switches / 2 + 1);
            else
                lifetime_state_1_current = area_gaussian_1 *sample_time_interval/(number_switches / 2 + 1);
                lifetime_state_2_current = 2 * area_gaussian_2 * sample_time_interval/ number_switches;
            end
        end
        error_lifetime_ratio(iteration_number) = abs(lifetime_state_1_current/lifetime_state_2_current - area_gaussian_1/area_gaussian_2);
        threshold_1_iteration_array(iteration_number) = threshold_point_1;
        threshold_2_iteration_array(iteration_number) = threshold_point_2;
        number_switches_both_states_iteration_array(iteration_number) = number_switches;
        clear phase_iteration_array_temp
        phase_iteration_array_temp(state_assignment == -1) = gaussian_1_mean;
        phase_iteration_array_temp(state_assignment == 1) = gaussian_2_mean;
        
        if gaussian_1_mean > gaussian_2_mean
            lifetime_state_1_iteration_array(iteration_number) = lifetime_state_1_current;
            lifetime_state_2_iteration_array(iteration_number) = lifetime_state_2_current;
        else
            lifetime_state_1_iteration_array(iteration_number) = lifetime_state_2_current;
            lifetime_state_2_iteration_array(iteration_number) = lifetime_state_1_current;
        end
        
        phase_iteration_array(iteration_number, 1 : length(time_data)) = zeros(1, length(time_data));
        phase_iteration_array(iteration_number, 1 : first_sure_state - 1) = RTS_data(1 : first_sure_state - 1);
        phase_iteration_array(iteration_number, first_sure_state : end) = phase_iteration_array_temp;
        iteration_number = iteration_number + 1;
    end
    if single_gaussian_fit_error < double_gaussian_fit_error || run_broken == 1
        clean_RTS_data = zeros(length(time_data), 1);
        error_lifetime_ratio = 0;
        lifetime_state_1_current = 0;
        lifetime_state_2_current = 0;
        lifetime_state_1_iteration_array = 0;
        lifetime_state_2_iteration_array = 0;
        lifetime_state_1_final_iteration = 0;
        lifetime_state_2_final_iteration = 0;
        threshold_1_iteration_array = 0;
        threshold_2_iteration_array = 0;
        phase_iteration_array = 0;
        number_switches_both_states_final_iteration = 0;
        clean_time_data = 0;
        hist_RTS_bins = hist_bin_middles;
    else
        %%%% shift back to original undo the processing to find peaks earlier.
        if fit_error_180 < fit_error_360 || fit_error_180 == fit_error_360
            clean_RTS_data = wrapTo180(phase_iteration_array(end, :) + peak_angle);
            raw_data_out = wrapTo180(raw_data_out + peak_angle);
            gaussian_1_mean = wrapTo180(gaussian_1_mean + peak_angle);
            gaussian_2_mean = wrapTo180(gaussian_2_mean + peak_angle);
            clean_time_data = time_data;
            lifetime_state_1_final_iteration = lifetime_state_1_current;
            lifetime_state_2_final_iteration = lifetime_state_2_current;
            hist_RTS_bins = wrapTo180(hist_bin_middles + peak_angle);
            number_switches_both_states_final_iteration = number_switches;
        else
            clean_RTS_data = wrapTo360(phase_iteration_array(end, :) + peak_angle) - 180;
            raw_data_out = wrapTo360(raw_data_out + peak_angle) - 180;
            gaussian_1_mean = wrapTo360(gaussian_1_mean + peak_angle) - 180;
            gaussian_2_mean = wrapTo360(gaussian_2_mean + peak_angle) - 180;
            clean_time_data = time_data;
            lifetime_state_1_final_iteration = lifetime_state_1_current;
            lifetime_state_2_final_iteration = lifetime_state_2_current;
            hist_RTS_bins = wrapTo360(hist_bin_middles + peak_angle) - 180;
            number_switches_both_states_final_iteration = number_switches;
        end            
    end
end