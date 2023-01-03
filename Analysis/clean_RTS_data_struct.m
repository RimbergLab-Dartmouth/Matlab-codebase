disp('cleaning RTS')
moving_mean_average_time = run_params.analysis.moving_mean_average_time*1e-6;
moving_mean_average_number = moving_mean_average_time * input_params.digitizer.sample_rate;

%% clean up phase data a little bit by shifting center to 0 degs, and by
%%%%% getting rid of gross outliers
raw_data.phase_extracted = wrapTo180(raw_data.phase_extracted - 180/pi *circ_mean(pi/180*raw_data.phase_extracted));
%% moving average of phase and amp (having done the cleaning above, the moving mean is the same as the moving circ mean)
raw_data.phase_moving_mean = movmean(raw_data.phase_extracted, moving_mean_average_number);
raw_data.amp_moving_mean = movmean(raw_data.amp_extracted, moving_mean_average_number);
raw_data.phase_corrected = raw_data.phase_moving_mean;

raw_data.phase_corrected(raw_data.phase_corrected > 180/pi*circ_mean(raw_data.phase_moving_mean*pi/180) + input_params.analysis.phase_outlier_cutoff) = NaN;
raw_data.phase_corrected(raw_data.phase_corrected < 180/pi*circ_mean(raw_data.phase_moving_mean*pi/180) - input_params.analysis.phase_outlier_cutoff) = NaN;

raw_data.time_corrected = raw_data.time;
raw_data.amp_corrected = raw_data.amp_extracted;
raw_data.amp_corrected(isnan(raw_data.phase_corrected)) = [];
raw_data.time_corrected(isnan(raw_data.phase_corrected)) = [];
raw_data.phase_corrected(isnan(raw_data.phase_corrected)) = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
run_params.analysis.bin_edges = -180:input_params.analysis.clean_RTS_bin_width:180;
%% Clean RTS data using function, and 
[temp.clean_time_data, temp.raw_data_out, temp.clean_RTS_data, temp.double_gaussian_existence, temp.gaussian_1_mean, temp.gaussian_2_mean, temp.sigma_double_gaussian, temp.double_gaussian_fit_error, ...
    temp.area_gaussian_1, temp.area_gaussian_2, temp.lifetime_state_1_final_iteration, temp.lifetime_state_2_final_iteration, temp.lifetime_state_1_iteration_array, ...
    temp.lifetime_state_2_iteration_array, temp.simple_threshold_clean_RTS_data, temp.simple_threshold_lifetime_state_1, temp.simple_threshold_lifetime_state_2, ...
    temp.threshold_1_iteration_array, temp.threshold_2_iteration_array, temp.number_switches_both_states_iteration_array, ...
    temp.number_switches_both_states_final_iteration, temp.gaussian_1_theory_values, temp.gaussian_2_theory_values, temp.hist_RTS_bins, ...
    temp.hist_count_data, temp.single_gaussian_fit_params, temp.single_gaussian_theory_values, temp.single_gaussian_fit_error] = ...
    clean_noisy_RTS_signal(raw_data.time_corrected, raw_data.phase_corrected, run_params.analysis.min_gaussian_center_to_center_phase, run_params.analysis.number_iterations, ...
            run_params.analysis.bin_edges, run_params.analysis.double_gaussian_fit_sigma_guess);
temp.gaussian_difference = abs(temp.gaussian_1_mean - temp.gaussian_2_mean)  ; 
%% Plotting Gaussian fits to RTS data
if run_params.plot_visible == 1
    RTS_Gaussians = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
elseif run_params.plot_visible == 0    
    RTS_Gaussians = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
end
bar(temp.hist_RTS_bins, temp.hist_count_data, 'DisplayName', 'raw data')
hold on
plot(temp.hist_RTS_bins, temp.gaussian_1_theory_values,'r', 'linewidth', 3,'DisplayName', 'Gaussian 1 theory')
plot(temp.hist_RTS_bins, temp.gaussian_2_theory_values,'k', 'linewidth', 3, 'DisplayName', 'Gaussian 2 theory')
plot(temp.hist_RTS_bins, temp.single_gaussian_theory_values,'g', 'linewidth', 3,'DisplayName', 'Gaussian 1 theory')
xlabel('Phase ($^\circ$)', 'interpreter', 'latex')
ylabel('Count', 'interpreter', 'latex')
title(['RTS Gaussians for P$_{\mathrm{in}}$ = ' num2str(run_params.input_power_value) 'dBm' 13 10 ...
    '$n_g = $' num2str(run_params.ng_1_value) ', $\Phi_{\mathrm{ext}}$ = ' num2str(run_params.flux_1_value) '$\Phi_0$' 13 10 ...
    '$\Delta$ = ' num2str(detuning_point) 'MHz' 13 10 ...
    'center gaussian 1 = ' num2str(round(temp.gaussian_1_mean, 2)) '$^\circ$, ' ...
    'center gaussian 2 = ' num2str(round(temp.gaussian_2_mean, 2)) '$^\circ$, ' ...
    'double gaussian $\sigma$ = ' num2str(round(temp.sigma_double_gaussian, 2)) '$^\circ$' 13 10 ...
    'single gaussian center = ' num2str(round(temp.single_gaussian_fit_params(2), 2)) '$^\circ$', ...
    'single gaussian $\sigma$ = ' num2str(round(temp.single_gaussian_fit_params(3), 2)) '$^\circ$'], 'interpreter', 'latex')
legend show

if run_params.save_data_and_png_param == 1
        save_file_name = [run_params.rts_fig_directory num2str(m_power) '_' num2str(m_bias_point) '_' num2str(m_detuning) '_' num2str(m_repetition) ...
            '_' num2str(run_params.input_power_value) 'dBm_' num2str(m_bias_point) '_ng_' num2str(run_params.ng_1_value) '_flux_' ...
            num2str(run_params.flux_1_value*1000) 'm_detuning_' num2str(detuning_point) 'MHz_RTS_gaussian.png'];
        saveas(RTS_Gaussians, save_file_name)
        if run_params.save_fig_file_param == 1
            save_file_name = [run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' num2str(m_bias_point) '_' num2str(m_detuning) '_' num2str(m_repetition) ...
            '_' num2str(run_params.input_power_value) 'dBm_' num2str(m_bias_point) '_ng_' num2str(run_params.ng_1_value) '_flux_' ...
            num2str(run_params.flux_1_value*1000) 'm_detuning_' num2str(detuning_point) 'MHz_RTS_gaussian.fig'];
            saveas(RTS_Gaussians, save_file_name)
        end
end
clear RTS_Gaussians ...
      save_file_name     
%% Plotting a section of the RTS
run_params.analysis.plotting_number_for_RTS = input_params.digitizer.sample_rate * run_params.analysis.plotting_time_for_RTS;
if run_params.plot_visible == 1
    RTS_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
elseif run_params.plot_visible == 0    
    RTS_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
end
start_point = randi([50e-6 * input_params.digitizer.sample_rate, length(raw_data.phase_corrected) - run_params.analysis.plotting_number_for_RTS - 1]);
plot(temp.clean_time_data(1,start_point : start_point + run_params.analysis.plotting_number_for_RTS)*1e6, ...
    raw_data.phase_extracted(1,start_point : start_point + run_params.analysis.plotting_number_for_RTS), 'r', 'DisplayName', 'raw data')
hold on
plot(raw_data.time_corrected(1,start_point : start_point + run_params.analysis.plotting_number_for_RTS)*1e6, ...
    squeeze(temp.raw_data_out(1, start_point : start_point + run_params.analysis.plotting_number_for_RTS)), ...
    'b', 'DisplayName', 'moving averaged data')
plot(raw_data.time_corrected(1, start_point : start_point + run_params.analysis.plotting_number_for_RTS)*1e6, ...
    squeeze(temp.clean_RTS_data(1, start_point : start_point + run_params.analysis.plotting_number_for_RTS)), ...
    'k', 'linewidth', 3, 'DisplayName', 'cleaned data')
xlabel('Time ($\mu$s)', 'interpreter', 'latex')
ylabel('Phase($S_{21}) (^\circ$)', 'interpreter', 'latex')
title(['RTS for P$_{\mathrm{in}}$ = ' num2str(run_params.input_power_value) 'dBm' 13 10 ...
    '$n_g = $' num2str(run_params.ng_1_value) ', $\Phi_{\mathrm{ext}}$ = ' num2str(run_params.flux_1_value) '$\Phi_0$' 13 10 ...
            '$\Delta$ = ' num2str(detuning_point) 'MHz' ], 'interpreter', 'latex')
legend show

if run_params.save_data_and_png_param == 1
        save_file_name = [run_params.rts_fig_directory num2str(m_power) '_' num2str(m_bias_point) '_' num2str(m_detuning) '_' num2str(m_repetition) ...
            '_' num2str(run_params.input_power_value) 'dBm_' num2str(m_bias_point) '_ng_' num2str(run_params.ng_1_value) '_flux_' ...
            num2str(run_params.flux_1_value*1000) 'm_detuning_' num2str(detuning_point) 'MHz_RTS_signal.png'];
        saveas(RTS_figure, save_file_name)
        if run_params.save_fig_file_param == 1
            save_file_name = [run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' num2str(m_bias_point) '_' num2str(m_detuning) '_' num2str(m_repetition) ...
            '_' num2str(run_params.input_power_value) 'dBm_' num2str(m_bias_point) '_ng_' num2str(run_params.ng_1_value) '_flux_' ...
            num2str(run_params.flux_1_value*1000) 'm_detuning_' num2str(detuning_point) 'MHz_RTS_signal.fig'];
            saveas(RTS_figure, save_file_name)
        end
end
clear RTS_figure ...
      save_file_name ...
      start_point
%% Find PSD of cleaned RTS signal    
if temp.double_gaussian_existence == 1 % no point analysing if double gaussian doesn't exist
    disp('finding PSD of RTS')
    [temp.freqs, temp.psd, temp.psd_dBm] = ...
        extract_PSD(raw_data.time_corrected, temp.clean_RTS_data);
end
%% Find theoretical Lorentzian from the obtained lifetimes 
if temp.double_gaussian_existence == 1
    temp.theory_lorentzian = 4*(abs(temp.gaussian_1_mean - temp.gaussian_2_mean))^2 * (temp.lifetime_state_1_final_iteration * temp.lifetime_state_2_final_iteration)^2 ...
        ./(temp.lifetime_state_1_final_iteration + temp.lifetime_state_2_final_iteration)^3 ./ (1 + 4*pi^2 .* temp.freqs.^2 ./ (1/temp.lifetime_state_1_final_iteration  + ...
        1 / temp.lifetime_state_2_final_iteration )^2);
end
%% Fit a Lorentzian to the PSD
if temp.double_gaussian_existence == 1
    % get rid of high frequency components. the moving mean got rid of that anyway
    temp.psd (temp.freqs > 3 / moving_mean_average_time) = [];
    temp.psd_dBm(temp.freqs > 3 / moving_mean_average_time) = [];
    temp.theory_lorentzian (temp.freqs > 3 / moving_mean_average_time) = [];
    temp.freqs(temp.freqs > 3 / moving_mean_average_time) = [];

    [temp.lifetime_state_1_lorentz_fit, temp.lifetime_state_2_lorentz_fit, temp.amp_diff_lorentz_fit, temp.theory_lorentzian_fit, temp.lorentz_fit_err] = ...
            fit_RTS_lorentzian(temp.freqs, temp.psd, temp.lifetime_state_1_final_iteration, temp.lifetime_state_2_final_iteration, abs(temp.gaussian_1_mean - temp.gaussian_2_mean));
end
%% neglect some unreasonable lifetime values 
temp.lifetime_state_1_final_iteration (temp.lifetime_state_1_final_iteration < 1/moving_mean_average_time) = NaN;
temp.lifetime_state_2_final_iteration (temp.lifetime_state_2_final_iteration < 1/moving_mean_average_time) = NaN;
temp.lifetime_state_1_final_iteration (temp.gaussian_difference < run_params.analysis.min_gaussian_center_to_center_phase) = NaN;
temp.lifetime_state_2_final_iteration (temp.gaussian_difference < run_params.analysis.min_gaussian_center_to_center_phase) = NaN;
temp.lifetime_state_1_final_iteration (temp.gaussian_difference > run_params.analysis.max_gaussian_center_to_center_phase) = NaN;
temp.lifetime_state_2_final_iteration (temp.gaussian_difference > run_params.analysis.max_gaussian_center_to_center_phase) = NaN;
temp.lifetime_state_1_final_iteration (temp.number_switches_both_states_final_iteration < input_params.minimum_number_switches) = NaN;
temp.lifetime_state_2_final_iteration (temp.number_switches_both_states_final_iteration < input_params.minimum_number_switches) = NaN;
temp.lifetime_state_1_final_iteration (temp.area_gaussian_1 > input_params.analysis.min_gaussian_count) = NaN;
temp.lifetime_state_2_final_iteration (temp.area_gaussian_2 > input_params.analysis.min_gaussian_count) = NaN;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plotting PSD 
if temp.double_gaussian_existence == 1
    if run_params.plot_visible == 1
        RTS_PSD_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    elseif run_params.plot_visible == 0 
        RTS_PSD_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
    end

    plot(temp.freqs/1e3, temp.psd_dBm, 'r', 'DisplayName', 'PSD data')
    hold on
    plot(temp.freqs/1e3, temp.theory_lorentzian, 'b', 'DisplayName', 'Theoretical Lorentzian')
    plot(temp.freqs/1e3, temp.theory_lorentzian_fit, 'k', 'DisplayName', 'Fit Lorentzian')
    xlabel('Freq (kHz)', 'interpreter', 'latex')
    ylabel('PSD (dBm))', 'interpreter', 'latex')
    title(['RTS PSD for P$_{\mathrm{in}}$ = ' num2str(run_params.input_power_value) 'dBm' 13 10 ...
        '$n_g = $' num2str(run_params.ng_1_value) ', $\Phi_{\mathrm{ext}}$ = ' num2str(run_params.flux_1_value) '$\Phi_0$' 13 10 ...
        '$\Delta$ = ' num2str(detuning_point) 'MHz' ...
        'lifetime 1 from RTS = ' num2str(round(temp.lifetime_state_1_final_iteration*1e6, 2)) '$\mu$s' ...
        'lifetime 2 from RTS = ' num2str(round(temp.lifetime_state_2_final_iteration*1e6, 2)) '$\mu$s' 13 10 ...
        'lifetime 1 from PSD fit = ' num2str(round(temp.lifetime_state_1_lorentz_fit*1e6, 2)) '$\mu$s' ...
        'lifetime 2 from PSD fit = ' num2str(round(temp.lifetime_state_2_lorentz_fit*1e6, 2)) '$\mu$s'], 'interpreter', 'latex')
    legend show

    if run_params.save_data_and_png_param == 1
            save_file_name = [run_params.rts_fig_directory num2str(m_power) '_' num2str(m_bias_point) '_' num2str(m_detuning) '_' num2str(m_repetition) ...
                '_' num2str(run_params.input_power_value) 'dBm_' num2str(m_bias_point) '_ng_' num2str(run_params.ng_1_value) '_flux_' ...
                num2str(run_params.flux_1_value*1000) 'm_detuning_' num2str(detuning_point) 'MHz_RTS_PSD.png'];
            saveas(RTS_PSD_figure, save_file_name)
            save_file_name = [run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' num2str(m_bias_point) '_' num2str(m_detuning) '_' num2str(m_repetition) ...
                '_' num2str(run_params.input_power_value) 'dBm_' num2str(m_bias_point) '_ng_' num2str(run_params.ng_1_value) '_flux_' ...
                num2str(run_params.flux_1_value*1000) 'm_detuning_' num2str(detuning_point) 'MHz_RTS_PSD.fig'];
            saveas(RTS_PSD_figure, save_file_name)
    end
    clear RTS_PSD_figure ...
          save_file_name
end
%% Assigning values to long term variables

run_params.analysis.current_run_double_gaussian_existence = temp.double_gaussian_existence;

analysis.gaussian_1_mean(m_power, m_bias_point, m_detuning, m_repetition) = temp.gaussian_1_mean;
analysis.gaussian_2_mean(m_power, m_bias_point, m_detuning, m_repetition) = temp.gaussian_2_mean;
analysis.gaussian_difference(m_power, m_bias_point, m_detuning, m_repetition) = temp.gaussian_difference;
analysis.sigma_double_gaussian(m_power, m_bias_point, m_detuning, m_repetition) = temp.sigma_double_gaussian;
analysis.double_gaussian_fit_error(m_power, m_bias_point, m_detuning, m_repetition) = temp.double_gaussian_fit_error;
analysis.area_gaussian_1(m_power, m_bias_point, m_detuning, m_repetition) = temp.area_gaussian_1;
analysis.area_gaussian_2(m_power, m_bias_point, m_detuning) = temp.area_gaussian_2;
analysis.number_switches_both_states_iteration_array(m_power, m_bias_point, m_detuning, m_repetition, :) = temp.number_switches_both_states_iteration_array;
analysis.number_switches_both_states_final_iteration(m_power, m_bias_point, m_detuning, m_repetition) = temp.number_switches_both_states_final_iteration;

analysis.lifetime_state_1_final_iteration(m_power, m_bias_point, m_detuning, m_repetition) = temp.lifetime_state_1_final_iteration;
analysis.lifetime_state_2_final_iteration(m_power, m_bias_point, m_detuning, m_repetition) = temp.lifetime_state_2_final_iteration;
analysis.lifetime_state_1_iteration_array(m_power, m_bias_point, m_detuning, m_repetition, 1:run_params.analysis.number_iterations) = ...
                                                            temp.lifetime_state_1_iteration_array;
analysis.lifetime_state_2_iteration_array(m_power, m_bias_point, m_detuning, m_repetition, 1:run_params.analysis.number_iterations) = ...
                                                            temp.lifetime_state_2_iteration_array;
analysis.simple_threshold_lifetime_state_1(m_power, m_bias_point, m_detuning, m_repetition) = temp.simple_threshold_lifetime_state_1;
analysis.simple_threshold_lifetime_state_2(m_power, m_bias_point, m_detuning, m_repetition) = temp.simple_threshold_lifetime_state_2;
analysis.threshold_1_iteration_array(m_power, m_bias_point, m_detuning, m_repetition, 1:run_params.analysis.number_iterations) = ...
                                                            temp.threshold_1_iteration_array;
analysis.threshold_2_iteration_array(m_power, m_bias_point, m_detuning, m_repetition, 1:run_params.analysis.number_iterations) = ...
                                                            temp.threshold_2_iteration_array;
analysis.gaussian_1_theory_values(m_power, m_bias_point, m_detuning, m_repetition, 1:length(run_params.analysis.bin_edges)-1) = ...
                                                            temp.gaussian_1_theory_values;
analysis.gaussian_2_theory_values(m_power, m_bias_point, m_detuning, m_repetition, 1:length(run_params.analysis.bin_edges)-1) = ...
                                                            temp.gaussian_2_theory_values;
analysis.hist_RTS_bins(m_power, m_bias_point, m_detuning, m_repetition, 1:length(run_params.analysis.bin_edges)-1) = ...
                                                            temp.hist_RTS_bins;
analysis.hist_count_data(m_power, m_bias_point, m_detuning, m_repetition, 1:length(run_params.analysis.bin_edges)-1) = ...
                                                            temp.hist_count_data;
analysis.single_gaussian_fit_params(m_power, m_bias_point, m_detuning, m_repetition, 1:3) = temp.single_gaussian_fit_params;
analysis.single_gaussian_theory_values(m_power, m_bias_point, m_detuning, m_repetition, 1:length(run_params.analysis.bin_edges)-1) = ...
                                                            temp.single_gaussian_theory_values;
analysis.single_gaussian_fit_error(m_power, m_bias_point, m_detuning, m_repetition) = temp.single_gaussian_fit_error;
analysis.sign_of_bistability(m_power, m_bias_point, m_detuning, m_repetition) = temp.double_gaussian_existence;

if temp.double_gaussian_existence == 1
    analysis.RTS_PSD.freqs(m_power, m_bias_point, m_detuning, m_repetition, 1:length(temp.freqs)) = temp.freqs;
    analysis.RTS_PSD.psd(m_power, m_bias_point, m_detuning, m_repetition,  1:length(temp.freqs)) = temp.psd;
    analysis.RTS_PSD.psd_dBm(m_power, m_bias_point, m_detuning, m_repetition,  1:length(temp.freqs)) = temp.psd_dBm;
    analysis.RTS_PSD.theory_lorentzian_values(m_power, m_bias_point, m_detuning, m_repetition,  1:length(temp.freqs)) = temp.theory_lorentzian;
    analysis.RTS_PSD.lorentzian_fit_theory(m_power, m_bias_point, m_detuning, m_repetition,  1:length(temp.freqs)) = temp.theory_lorentzian_fit;
    analysis.RTS_PSD.lorentzian_fit_lifetime_state_1(m_power, m_bias_point, m_detuning, m_repetition) = temp.lifetime_state_1_lorentz_fit;
    analysis.RTS_PSD.lorentzian_fit_lifetime_state_2(m_power, m_bias_point, m_detuning, m_repetition) = temp.lifetime_state_2_lorentz_fit;
    analysis.RTS_PSD.lorentzian_fit_amp_diff(m_power, m_bias_point, m_detuning, m_repetition) = temp.amp_diff_lorentz_fit;
    analysis.RTS_PSD.lorentzian_fit_err(m_power, m_bias_point, m_detuning, m_repetition) = temp.lorentz_fit_err;
end

%%%% store necessary time data, delete rest
if run_params.analysis.plotting_time_for_RTS ~= 0
    input_params.start_index_of_RTS_raw_data_to_store = input_params.start_time_of_RTS_raw_data_to_store * input_params.digitizer.sample_rate;
    input_params.length_of_RTS_raw_data_to_store = input_params.time_length_of_RTS_raw_data_to_store * input_params.digitizer.sample_rate; 
    if input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store > length(temp.raw_data_out)
        input_params.start_index_of_RTS_raw_data_to_store = length(temp.raw_data_out) - input_params.length_of_RTS_raw_data_to_store - 1;
    end
    
    analysis.RTS.moving_mean_average_phase(m_power, m_bias_point, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
        temp.raw_data_out(input_params.start_index_of_RTS_raw_data_to_store : input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1);

    data.RTS.time(m_power, m_bias_point, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...    
        raw_data.time_corrected(input_params.start_index_of_RTS_raw_data_to_store : input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1);
    
    data.RTS.raw_phase(m_power, m_bias_point, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
        raw_data.phase_extracted(input_params.start_index_of_RTS_raw_data_to_store : input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1);

    data.RTS.raw_amp(m_power, m_bias_point, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
        raw_data.amp_extracted(input_params.start_index_of_RTS_raw_data_to_store : input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1);

    analysis.RTS.moving_mean_average_amp(m_power, m_bias_point, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
        raw_data.amp_moving_mean(input_params.start_index_of_RTS_raw_data_to_store : input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1);

    analysis.RTS.clean_RTS_phase(m_power, m_bias_point, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
        temp.clean_RTS_data(input_params.start_index_of_RTS_raw_data_to_store : input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1);

    analysis.RTS.simple_threshold_clean_RTS_data(m_power, m_bias_point, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
        temp.simple_threshold_clean_RTS_data(input_params.start_index_of_RTS_raw_data_to_store : input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1);
end

clear moving_mean_average_time ...
      moving_mean_average_number ...
      raw_data
close all      
%% Function Clean RTS from noisy data
function [clean_time_data, raw_data_out, clean_RTS_data, double_gaussian_existence, gaussian_1_mean, gaussian_2_mean, sigma_double_gaussian, double_gaussian_fit_error, area_gaussian_1, area_gaussian_2, ...
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
        raw_data_out = RTS_data;
        gaussian_1_mean = 0;
        gaussian_2_mean = 0;
        sigma_double_gaussian = 0;
        double_gaussian_fit_error = 1e9;
        area_gaussian_1 = 1e9;
        area_gaussian_2 = 1e9;
        lifetime_state_1_final_iteration = 0;
        lifetime_state_2_final_iteration = 0;
        lifetime_state_1_iteration_array = 0;
        lifetime_state_2_iteration_array = 0;
        simple_threshold_clean_RTS_data = RTS_data;
        simple_threshold_lifetime_state_1 = 0;
        simple_threshold_lifetime_state_2 = 0;
        threshold_1_iteration_array = 0;
        threshold_2_iteration_array = 0;
        number_switches_both_states_final_iteration = 0;
        number_switches_both_states_iteration_array = zeros(1, number_iterations);
        gaussian_1_theory_values = 0;
        gaussian_2_theory_values = 0;
        hist_RTS_bins = 0;
        hist_count_data = 0;
        single_gaussian_fit_params = 0;
        single_gaussian_theory_values = 0;
        single_gaussian_fit_error = 0;
        double_gaussian_existence = 0;
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
    
    if single_gaussian_fit_error < min(fit_error_360, fit_error_180) 
        clean_time_data = time_data;
        clean_RTS_data = RTS_data;
        raw_data_out = RTS_data;        
        gaussian_1_mean = 0;
        gaussian_2_mean = 0;
        sigma_double_gaussian = 0;
        double_gaussian_fit_error = 1e9;
        area_gaussian_1 = 1e9;
        area_gaussian_2 = 1e9;
        lifetime_state_1_final_iteration = 0;
        lifetime_state_2_final_iteration = 0;
        lifetime_state_1_iteration_array = 0;
        lifetime_state_2_iteration_array = 0;
        simple_threshold_clean_RTS_data = RTS_data;
        simple_threshold_lifetime_state_1 = 0;
        simple_threshold_lifetime_state_2 = 0;
        threshold_1_iteration_array = 0;
        threshold_2_iteration_array = 0;
        number_switches_both_states_final_iteration = 0;
        number_switches_both_states_iteration_array = zeros(1, number_iterations);
        gaussian_1_theory_values = 0;
        gaussian_2_theory_values = 0;
        hist_RTS_bins = hist_bin_middles;
        double_gaussian_existence = 0;  % decides if there are any signs of bistability. if not, no point analysing further
        return
    end
    
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
    clear error_lifetime_ratio ...
          threshold_1_iteration_array ...
          threshold_2_iteration_array ...
          number_switches_both_states_iteration_array ...
          lifetime_state_1_iteration_array ...
          lifetime_state_2_iteration_array ...
          phase_iteration_array  
      
    error_lifetime_ratio = zeros(number_iterations, 1);
    threshold_1_iteration_array = zeros(number_iterations, 1);
    threshold_2_iteration_array = zeros(number_iterations, 1);
    number_switches_both_states_iteration_array = zeros(number_iterations, 1);
    lifetime_state_1_iteration_array = zeros(number_iterations, 1);
    lifetime_state_2_iteration_array = zeros(number_iterations, 1);
    phase_iteration_array = zeros(number_iterations, length(time_data));
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
            clear hist_value_corresponding_gaussian_1 ...
                  hist_value_corresponding_gaussian_2 ...
                  separator_ratio_value 
            hist_value_corresponding_gaussian_1 = zeros(length(fitting_times), 1);
            hist_value_corresponding_gaussian_2 = zeros(length(fitting_times), 1);
            separator_ratio_value = zeros(length(fitting_times), 1);
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
        phase_iteration_array_temp = zeros(size(state_assignment));
        phase_iteration_array_temp(state_assignment == -1) = gaussian_1_mean;
        phase_iteration_array_temp(state_assignment == 1) = gaussian_2_mean;
        
        if gaussian_1_mean > gaussian_2_mean
            lifetime_state_1_iteration_array(iteration_number) = lifetime_state_1_current;
            lifetime_state_2_iteration_array(iteration_number) = lifetime_state_2_current;
        else
            lifetime_state_1_iteration_array(iteration_number) = lifetime_state_2_current;
            lifetime_state_2_iteration_array(iteration_number) = lifetime_state_1_current;
        end
        
        phase_iteration_array(iteration_number, 1 : first_sure_state - 1) = RTS_data(1 : first_sure_state - 1);
        phase_iteration_array(iteration_number, first_sure_state : end) = phase_iteration_array_temp;
        iteration_number = iteration_number + 1;
    end
    if single_gaussian_fit_error < double_gaussian_fit_error || run_broken == 1
        lifetime_state_1_current = 0;
        lifetime_state_2_current = 0;
        lifetime_state_1_iteration_array = 0;
        lifetime_state_2_iteration_array = 0;
        lifetime_state_1_final_iteration = lifetime_state_1_current;
        lifetime_state_2_final_iteration = lifetime_state_2_current;
        threshold_1_iteration_array = 0;
        threshold_2_iteration_array = 0;
        phase_iteration_array(iteration_number, :) = 0;
        clean_RTS_data = phase_iteration_array(end, :);
        number_switches_both_states_final_iteration = 0;
        clean_time_data = time_data;
        clean_RTS_data = RTS_data;
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
            double_gaussian_existence = 1;
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
            double_gaussian_existence = 1;
        end            
    end
end