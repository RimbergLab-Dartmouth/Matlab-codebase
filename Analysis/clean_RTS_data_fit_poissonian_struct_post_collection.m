%% post run analysis params
post_run_params.directory_to_be_analyzed = 'C:\Users\Sisira\Desktop\data';
post_run_params.file_to_load_input_params_from = ['C:\Users\Sisira\Desktop\data\' ...
        'switching_finder_comprehensive_data.mat'];
post_run_params.file_to_save_post_run_analysis_separately  = ['C:\Users\Sisira\Desktop\data\' ...
        'switching_finder_only_analysis.mat'];
post_run_params.plot_visible = 0;    
post_run_params.analysis.moving_mean_average_time = 3e-6; % in seconds
post_run_params.analysis.min_gaussian_center_to_center_phase = 15;
post_run_params.analysis.max_gaussian_center_to_center_phase = 60;
post_run_params.analysis.number_iterations = 5;
post_run_params.min_gaussian_count = 1500;
post_run_params.phase_outlier_cutoff = 70; % in degs, this is the phase above and below the mean phase, over which the phase is classified as an outlier (after moving mean)
post_run_params.analysis.clean_RTS_bin_width = 6; % degs - phase histogramming bin size
post_run_params.analysis.double_gaussian_fit_sigma_guess = 15;
post_run_params.analysis.plotting_time_for_RTS = 150e-6;
post_run_params.analysis.storing_time_for_RTS = 50e-6;
post_run_params.minimum_number_switches = 50; % if there aren't atleast this many switching events, the Poisson fit is not done.
post_run_params.poissonian_fit_bin_number = 25;
post_run_params.poissonian_lifetime_repetitions_mode = 'separate_and_together';  % 'separate' or 'averaged', 'histogrammed_together'
post_run_params.analysis.save_RTS_PSD_extended_data = 0; % decides whether to save RTS PSD extracted or not, and also, RTS data for above storage time
post_run_params.rts_fig_directory = [cd '\plots\rts\'];
post_run_params.fig_directory = [cd '\plots\'];
post_run_params.save_png_param = 1;
post_run_params.save_data_param = 1;
post_run_params.save_fig_file_param = 0;

load(post_run_params.file_to_load_input_params_from, 'input_params', 'post_run_analysis', 'data')


%%%% temp testing code
% input_params.analyzed_parameter = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
%     length(input_params.ng_1_value_list), input_params.detuning_array_number, run_params.number_repetitions);

% input_params.analyzed_parameter = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
%     length(input_params.ng_1_value_list), 201, 10);
%%%%%

%%%% ignore files that have already been analyzed, and also comprehensive
%%%% data and only analysis files 
temp_filelist.files = ls(post_run_params.directory_to_be_analyzed);

temp_filelist.files = string(temp_filelist.files);

temp_filelist.unanalyzed_files_finder = contains(temp_filelist.files, 'analyzed');

temp_filelist.raw_data_files_list = temp_filelist.files(~temp_filelist.unanalyzed_files_finder);

temp_filelist.raw_data_files_list_finder = contains(temp_filelist.raw_data_files_list, 'comprehensive_data');

temp_filelist.raw_data_files_list = temp_filelist.raw_data_files_list(~temp_filelist.raw_data_files_list_finder);

temp_filelist.raw_data_files_list_finder = contains(temp_filelist.raw_data_files_list, 'only_analysis');

temp_filelist.raw_data_files_list = temp_filelist.raw_data_files_list(~temp_filelist.raw_data_files_list_finder);
%%%%%%%
for m_record_count = 3 : length(temp_filelist.raw_data_files_list)
    temp_filelist.file_name = temp_filelist.raw_data_files_list(m_record_count);
    temp_filelist.file_name = convertStringsToChars(temp_filelist.file_name);
%     if contains(temp_filelist.files, [temp_filelist.file_name '_analyzed'])
%         return
%         disp('skip')
%     end
    
    load([post_run_params.directory_to_be_analyzed '\' temp_filelist.file_name])
    disp(['loaded file ' temp_filelist.file_name])
    
    for m_data_counter = 1 : size(raw_data_matrix.voltage, 1)        
        m_power = raw_data_matrix.input_power_number(m_data_counter);
        m_flux = raw_data_matrix.flux_number(m_data_counter);
        m_gate = raw_data_matrix.ng_number(m_data_counter);
        m_detuning = raw_data_matrix.detuning_point_number(m_data_counter);
        m_bias_point = raw_data_matrix.bias_point_number(m_data_counter);
        detuning_point = raw_data_matrix.detuning_point(m_data_counter);
        for m_repetition = 1 : squeeze(data.repetition_number(m_power, m_flux, m_gate, m_detuning))
    %         %%%% temp testing code
    %         temp_filelist.bias_extractor = temp_filelist.file_name(1:9);
    %         raw_data_matrix.input_power_number(m_data_counter) = str2double(temp_filelist.file_name(1));
    %         raw_data_matrix.ng_number(m_data_counter) = str2double(temp_filelist.file_name(5));
    %         raw_data_matrix.flux_number(m_data_counter) = str2double(temp_filelist.file_name(3));
    %         raw_data_matrix.repetition_number(m_data_counter) = mod(m_data_counter - 1, 2) + 1;
    %         raw_data_matrix.detuning_point(m_data_counter) = m_data_counter;
    %         raw_data_matrix.detuning_point_number(m_data_counter) = m_data_counter;
    %         raw_data_matrix.bias_point_number(m_data_counter) = (raw_data_matrix.flux_number(m_data_counter) - 1)* 8 + raw_data_matrix.ng_number(m_data_counter);
    %         %%%%%%%
            %% demodulate to extract amplitude and phase
            raw_data.voltage = squeeze(raw_data_matrix.voltage(m_data_counter, m_repetition, :));
            raw_data.size_required = size(raw_data.voltage');
            raw_data.voltage = reshape(raw_data.voltage', [], 1);
            raw_data.time  = 0:1/input_params.digitizer.sample_rate : length(raw_data.voltage)/input_params.digitizer.sample_rate-1/input_params.digitizer.sample_rate;
            raw_data.time = raw_data.time';
            [raw_data.amp_extracted, raw_data.phase_extracted] = ...
                                    get_amp_and_phase(raw_data.time, raw_data.voltage, input_params.if_freq, input_params.digitizer.sample_rate);

            raw_data.amp_extracted = reshape(raw_data.amp_extracted', raw_data.size_required)';
            raw_data.phase_extracted = 180/pi*reshape(raw_data.phase_extracted', raw_data.size_required)';
            raw_data.time = reshape(raw_data.time', raw_data.size_required)';
            raw_data.voltage = reshape(raw_data.voltage', raw_data.size_required)';

            disp(['cleaning RTS for power number = ' num2str(m_power) ', flux number = ' ...
            num2str(m_flux) ', ' 13 'gate number = ' num2str(m_gate) ...
            ', detuning number = ' num2str(m_detuning) ', repetition number = ' ...
                num2str(m_repetition) 13 10 13 10])

            moving_mean_average_time = post_run_params.analysis.moving_mean_average_time;
            moving_mean_average_number = moving_mean_average_time * input_params.digitizer.sample_rate;
            %% clean up phase data a little bit by shifting center to 0 degs, and by
            %%%%% getting rid of gross outliers
            raw_data.phase_extracted = wrapTo180(raw_data.phase_extracted - 180/pi *circ_mean(pi/180*raw_data.phase_extracted));
            %% moving average of phase and amp (having done the cleaning above, the moving mean is the same as the moving circ mean)
            raw_data.phase_moving_mean = movmean(raw_data.phase_extracted, moving_mean_average_number);
            raw_data.amp_moving_mean = movmean(raw_data.amp_extracted, moving_mean_average_number);
            raw_data.phase_corrected = raw_data.phase_moving_mean;

            raw_data.phase_corrected(raw_data.phase_corrected > 180/pi*circ_mean(raw_data.phase_moving_mean*pi/180) + post_run_params.phase_outlier_cutoff) = NaN;
            raw_data.phase_corrected(raw_data.phase_corrected < 180/pi*circ_mean(raw_data.phase_moving_mean*pi/180) - post_run_params.phase_outlier_cutoff) = NaN;

            raw_data.time_corrected = raw_data.time;
            raw_data.amp_corrected = raw_data.amp_extracted;
            raw_data.amp_corrected(isnan(raw_data.phase_corrected)) = [];
            raw_data.time_corrected(isnan(raw_data.phase_corrected)) = [];
            raw_data.phase_corrected(isnan(raw_data.phase_corrected)) = [];
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            post_run_params.analysis.bin_edges = -180:post_run_params.analysis.clean_RTS_bin_width:180;
            %% Clean RTS data using function, and 
            [temp.clean_time_data, temp.raw_data_out, temp.clean_RTS_data, temp.double_gaussian_existence, temp.gaussian_1_mean, temp.gaussian_2_mean, temp.sigma_double_gaussian, temp.double_gaussian_fit_error, ...
                temp.area_gaussian_1, temp.area_gaussian_2, temp.lifetime_state_1_final_iteration, temp.lifetime_state_2_final_iteration, temp.lifetime_state_1_iteration_array, ...
                temp.lifetime_state_2_iteration_array, temp.simple_threshold_clean_RTS_data, temp.simple_threshold_lifetime_state_1, temp.simple_threshold_lifetime_state_2, ...
                temp.threshold_1_iteration_array, temp.threshold_2_iteration_array, temp.number_switches_both_states_iteration_array, ...
                temp.number_switches_both_states_final_iteration, temp.gaussian_1_theory_values, temp.gaussian_2_theory_values, temp.hist_RTS_bins, ...
                temp.hist_count_data, temp.single_gaussian_fit_params, temp.single_gaussian_theory_values, temp.single_gaussian_fit_error] = ...
                clean_noisy_RTS_signal(raw_data.time_corrected, raw_data.phase_corrected, post_run_params.analysis.min_gaussian_center_to_center_phase, post_run_params.analysis.number_iterations, ...
                        post_run_params.analysis.bin_edges, post_run_params.analysis.double_gaussian_fit_sigma_guess);
            temp.gaussian_difference = abs(temp.gaussian_1_mean - temp.gaussian_2_mean)  ; 
            %% Plotting Gaussian fits to RTS data
            if post_run_params.plot_visible == 1
                RTS_Gaussians = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
            elseif post_run_params.plot_visible == 0    
                RTS_Gaussians = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
            end
            bar(temp.hist_RTS_bins, temp.hist_count_data, 'DisplayName', 'raw data')
            hold on
            if temp.double_gaussian_existence 
                plot(temp.hist_RTS_bins, temp.gaussian_1_theory_values,'r', 'linewidth', 3,'DisplayName', 'Gaussian 1 theory')
                plot(temp.hist_RTS_bins, temp.gaussian_2_theory_values,'k', 'linewidth', 3, 'DisplayName', 'Gaussian 2 theory')
                plot(temp.hist_RTS_bins, temp.gaussian_1_theory_values + temp.gaussian_2_theory_values,'y', 'linewidth', 3, 'DisplayName', 'Double Gaussian theory')
            end
            plot(temp.hist_RTS_bins, temp.single_gaussian_theory_values,'g', 'linewidth', 3,'DisplayName', 'Single Gaussian theory')
            xlabel('Phase ($^\circ$)', 'interpreter', 'latex')
            ylabel('Count', 'interpreter', 'latex')
            title(['RTS Gaussians for P$_{\mathrm{in}}$ = ' num2str(input_params.input_power_value_list(m_power)) 'dBm' 13 10 ...
                '$n_g = $' num2str(input_params.ng_1_value_list(m_gate)) ', $\Phi_{\mathrm{ext}}$ = ' ...
                num2str(input_params.flux_1_value_list(m_flux)) '$\Phi_0$' 13 10 ...
                '$\Delta$ = ' num2str(raw_data_matrix.detuning_point(m_data_counter)) 'MHz, ' ...
                'Repetition number= ' num2str(m_repetition) 13 10 ...
                'center gaussian 1 = ' num2str(round(temp.gaussian_1_mean, 2)) '$^\circ$, ' ...
                'center gaussian 2 = ' num2str(round(temp.gaussian_2_mean, 2)) '$^\circ$, ' ...
                'double gaussian $\sigma$ = ' num2str(round(temp.sigma_double_gaussian, 2)) '$^\circ$' 13 10 ...
                'single gaussian center = ' num2str(round(temp.single_gaussian_fit_params(2), 2)) '$^\circ$', ...
                'single gaussian $\sigma$ = ' num2str(round(temp.single_gaussian_fit_params(3), 2)) '$^\circ$'], 'interpreter', 'latex')
            legend show

            if post_run_params.save_png_param == 1
                    save_file_name = [post_run_params.rts_fig_directory num2str(m_power) '_' ...
                        num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning) ...
                        '_' num2str(m_repetition) ...
                        '_' num2str(input_params.input_power_value_list(m_power)) 'dBm_' ...
                        '_ng_' num2str(input_params.ng_1_value_list(m_gate)) '_flux_' ...
                        num2str(input_params.flux_1_value_list(m_flux)*1000) 'm_detuning_' ...
                        num2str(raw_data_matrix.detuning_point(m_data_counter)) 'MHz_RTS_gaussian.png'];
                    saveas(RTS_Gaussians, save_file_name)
                    if post_run_params.save_fig_file_param == 1
                        save_file_name = [post_run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' ...
                        num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning) ...
                        '_' num2str(m_repetition) ...
                        '_' num2str(input_params.input_power_value_list(m_power)) 'dBm_' ...
                        '_ng_' num2str(input_params.ng_1_value_list(m_gate)) '_flux_' ...
                        num2str(input_params.flux_1_value_list(m_flux)*1000) 'm_detuning_' ...
                        num2str(raw_data_matrix.detuning_point(m_data_counter)) 'MHz_RTS_gaussian.fig'];
                        saveas(RTS_Gaussians, save_file_name)
                    end
            end
            clear RTS_Gaussians ...
                  save_file_name     
            %% Plotting a section of the RTS
            post_run_params.analysis.plotting_number_for_RTS = input_params.digitizer.sample_rate * post_run_params.analysis.plotting_time_for_RTS;
            if post_run_params.plot_visible == 1
                RTS_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
            elseif post_run_params.plot_visible == 0    
                RTS_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
            end
            start_point = randi([50e-6 * input_params.digitizer.sample_rate, length(raw_data.phase_corrected) - post_run_params.analysis.plotting_number_for_RTS - 1]);
            plot(temp.clean_time_data(start_point : start_point + post_run_params.analysis.plotting_number_for_RTS)*1e6, ...
                raw_data.phase_extracted(start_point : start_point + post_run_params.analysis.plotting_number_for_RTS), 'r', 'DisplayName', 'raw data')
            hold on
            plot(raw_data.time_corrected(start_point : start_point + post_run_params.analysis.plotting_number_for_RTS)*1e6, ...
                squeeze(temp.raw_data_out(start_point : start_point + post_run_params.analysis.plotting_number_for_RTS)), ...
                'b', 'DisplayName', 'moving averaged data')
            plot(raw_data.time_corrected(start_point : start_point + post_run_params.analysis.plotting_number_for_RTS)*1e6, ...
                squeeze(temp.clean_RTS_data(start_point : start_point + post_run_params.analysis.plotting_number_for_RTS)), ...
                'k', 'linewidth', 3, 'DisplayName', 'cleaned data')
            xlabel('Time ($\mu$s)', 'interpreter', 'latex')
            ylabel('Phase($S_{21}) (^\circ$)', 'interpreter', 'latex')
            title(['RTS for P$_{\mathrm{in}}$ = ' num2str(input_params.input_power_value_list(m_power)) 'dBm' 13 10 ...
                '$n_g = $' num2str(input_params.ng_1_value_list(m_gate)) ', $\Phi_{\mathrm{ext}}$ = ' ...
                num2str(input_params.flux_1_value_list(m_flux)) '$\Phi_0$' 13 10 ...
                        '$\Delta$ = ' num2str(raw_data_matrix.detuning_point(m_data_counter)) 'MHz, ' ...
                'Repetition number= ' num2str(m_repetition)], 'interpreter', 'latex')
            legend show

            if post_run_params.save_png_param == 1
                    save_file_name = [post_run_params.rts_fig_directory num2str(m_power) '_' ...
                        num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning) ...
                        '_' num2str(m_repetition) ...
                        '_' num2str(input_params.input_power_value_list(m_power)) 'dBm_' ...
                        '_ng_' num2str(input_params.ng_1_value_list(m_gate)) '_flux_' ...
                        num2str(input_params.flux_1_value_list(m_flux)*1000) 'm_detuning_' ...
                        num2str(raw_data_matrix.detuning_point(m_data_counter)) 'MHz_RTS_signal.png'];
                    saveas(RTS_figure, save_file_name)
                    if post_run_params.save_fig_file_param == 1
                        save_file_name = [post_run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' ...
                        num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning) ...
                        '_' num2str(m_repetition) ...
                        '_' num2str(input_params.input_power_value_list(m_power)) 'dBm_' ...
                        '_ng_' num2str(input_params.ng_1_value_list(m_gate)) '_flux_' ...
                        num2str(input_params.flux_1_value_list(m_flux)*1000) 'm_detuning_' ...
                        num2str(raw_data_matrix.detuning_point(m_data_counter)) 'MHz_RTS_signal_sample.fig'];
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
                %%%% see eqn. 9.34 in https://www.nii.ac.jp/qis/first-quantum/e/forStudents/lecture/pdf/noise/chapter9.pdf
                %%%% or
                %%%%% eqn. 3.28 of https://ris.utwente.nl/ws/portalfiles/portal/6038220/thesis-Kolhatkar.pdf 
                temp.theory_lorentzian = 4*(abs(temp.gaussian_1_mean - temp.gaussian_2_mean))^2 ./ ((temp.lifetime_state_1_final_iteration + temp.lifetime_state_2_final_iteration) .* ...
                    ((1/temp.lifetime_state_1_final_iteration + 1/ temp.lifetime_state_2_final_iteration)^2 + (2*pi*temp.freqs).^2));
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
            % temp.lifetime_state_1_final_iteration (temp.lifetime_state_1_final_iteration < 1/moving_mean_average_time) = NaN;
            % temp.lifetime_state_2_final_iteration (temp.lifetime_state_2_final_iteration < 1/moving_mean_average_time) = NaN;
            % temp.lifetime_state_1_final_iteration (temp.gaussian_difference < post_run_params.analysis.min_gaussian_center_to_center_phase) = NaN;
            % temp.lifetime_state_2_final_iteration (temp.gaussian_difference < post_run_params.analysis.min_gaussian_center_to_center_phase) = NaN;
            % temp.lifetime_state_1_final_iteration (temp.gaussian_difference > post_run_params.analysis.max_gaussian_center_to_center_phase) = NaN;
            % temp.lifetime_state_2_final_iteration (temp.gaussian_difference > post_run_params.analysis.max_gaussian_center_to_center_phase) = NaN;
            % temp.lifetime_state_1_final_iteration (temp.number_switches_both_states_final_iteration < input_params.minimum_number_switches) = NaN;
            % temp.lifetime_state_2_final_iteration (temp.number_switches_both_states_final_iteration < input_params.minimum_number_switches) = NaN;
            % temp.lifetime_state_1_final_iteration (temp.area_gaussian_1 > post_run_params.min_gaussian_count) = NaN;
            % temp.lifetime_state_2_final_iteration (temp.area_gaussian_2 > post_run_params.min_gaussian_count) = NaN;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Plotting PSD 
            if temp.double_gaussian_existence == 1
                if post_run_params.plot_visible == 1
                    RTS_PSD_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
                elseif post_run_params.plot_visible == 0 
                    RTS_PSD_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
                end

                semilogx(temp.freqs/1e3, temp.psd_dBm, 'r', 'DisplayName', 'PSD data')
                hold on
                semilogx(temp.freqs/1e3, convert_fraction_to_dB(temp.theory_lorentzian), 'b', 'linewidth', 3, 'DisplayName', 'Theoretical Lorentzian')
                semilogx(temp.freqs/1e3, convert_fraction_to_dB(temp.theory_lorentzian_fit), 'k', 'linewidth', 3, 'DisplayName', 'Fit Lorentzian')
                xlabel('Freq (kHz)', 'interpreter', 'latex')
                ylabel('PSD (dB $^\circ$))', 'interpreter', 'latex')

                title(['RTS PSD for P$_{\mathrm{in}}$ = ' num2str(input_params.input_power_value_list(m_power)) 'dBm' 13 10 ...
                    '$n_g = $' num2str(input_params.ng_1_value_list(m_gate)) ', $\Phi_{\mathrm{ext}}$ = ' ...
                    num2str(input_params.flux_1_value_list(m_flux)) '$\Phi_0$' 13 10 ...
                    '$\Delta$ = ' num2str(raw_data_matrix.detuning_point(m_data_counter)) 'MHz, ' ...
                    'Repetition number= ' num2str(m_repetition) 13 10 ... ...
                    'lifetime 1 from RTS = ' num2str(round(temp.lifetime_state_1_final_iteration*1e6, 2)) '$\mu$s, ' ...
                    'lifetime 2 from RTS = ' num2str(round(temp.lifetime_state_2_final_iteration*1e6, 2)) '$\mu$s' 13 10 ...
                    'lifetime 1 from PSD fit = ' num2str(round(temp.lifetime_state_1_lorentz_fit*1e6, 2)) '$\mu$s, ' ...
                    'lifetime 2 from PSD fit = ' num2str(round(temp.lifetime_state_2_lorentz_fit*1e6, 2)) '$\mu$s'], 'interpreter', 'latex')
                legend show

                if post_run_params.save_png_param == 1
                    save_file_name = [post_run_params.rts_fig_directory num2str(m_power) '_' ...
                        num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning) ...
                        '_' num2str(m_repetition) ...
                        '_' num2str(input_params.input_power_value_list(m_power)) 'dBm_' ...
                        '_ng_' num2str(input_params.ng_1_value_list(m_gate)) '_flux_' ...
                        num2str(input_params.flux_1_value_list(m_flux)*1000) 'm_detuning_' ...
                        num2str(raw_data_matrix.detuning_point(m_data_counter)) 'MHz_RTS_PSD.png'];
                    saveas(RTS_PSD_figure, save_file_name)
                    if post_run_params.save_fig_file_param == 1
                        save_file_name = [post_run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' ...
                        num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning) ...
                        '_' num2str(m_repetition) ...
                        '_' num2str(input_params.input_power_value_list(m_power)) 'dBm_' ...
                        '_ng_' num2str(input_params.ng_1_value_list(m_gate)) '_flux_' ...
                        num2str(input_params.flux_1_value_list(m_flux)*1000) 'm_detuning_' ...
                        num2str(raw_data_matrix.detuning_point(m_data_counter)) 'MHz_RTS_PSD.fig'];
                        saveas(RTS_PSD_figure, save_file_name)
                    end
                end

                clear RTS_PSD_figure ...
                      save_file_name
            end
            %% Assigning values to long term variables

            post_run_params.analysis.current_run_bistability_existence = temp.double_gaussian_existence;

            post_run_analysis.gaussian_1_mean(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.gaussian_1_mean;
            post_run_analysis.gaussian_2_mean(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.gaussian_2_mean;
            post_run_analysis.gaussian_difference(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.gaussian_difference;
            post_run_analysis.sigma_double_gaussian(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.sigma_double_gaussian;
            post_run_analysis.double_gaussian_fit_error(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.double_gaussian_fit_error;
            post_run_analysis.area_gaussian_1(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.area_gaussian_1;
            post_run_analysis.area_gaussian_2(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.area_gaussian_2;
            post_run_analysis.number_switches_both_states_iteration_array(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.number_switches_both_states_iteration_array;
            post_run_analysis.number_switches_both_states_final_iteration(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.number_switches_both_states_final_iteration;

            post_run_analysis.lifetime_state_1_final_iteration(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.lifetime_state_1_final_iteration;
            post_run_analysis.lifetime_state_2_final_iteration(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.lifetime_state_2_final_iteration;
            post_run_analysis.lifetime_state_1_iteration_array(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:post_run_params.analysis.number_iterations) = ...
                                                                        temp.lifetime_state_1_iteration_array;
            post_run_analysis.lifetime_state_2_iteration_array(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:post_run_params.analysis.number_iterations) = ...
                                                                        temp.lifetime_state_2_iteration_array;
            post_run_analysis.simple_threshold_lifetime_state_1(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.simple_threshold_lifetime_state_1;
            post_run_analysis.simple_threshold_lifetime_state_2(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.simple_threshold_lifetime_state_2;
            post_run_analysis.threshold_1_iteration_array(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:post_run_params.analysis.number_iterations) = ...
                                                                        temp.threshold_1_iteration_array;
            post_run_analysis.threshold_2_iteration_array(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:post_run_params.analysis.number_iterations) = ...
                                                                        temp.threshold_2_iteration_array;
            post_run_analysis.gaussian_1_theory_values(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:length(post_run_params.analysis.bin_edges)-1) = ...
                                                                        temp.gaussian_1_theory_values;
            post_run_analysis.gaussian_2_theory_values(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:length(post_run_params.analysis.bin_edges)-1) = ...
                                                                        temp.gaussian_2_theory_values;
            post_run_analysis.hist_RTS_bins(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:length(post_run_params.analysis.bin_edges)-1) = ...
                                                                        temp.hist_RTS_bins;
            post_run_analysis.hist_count_data(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:length(post_run_params.analysis.bin_edges)-1) = ...
                                                                        temp.hist_count_data;
            post_run_analysis.single_gaussian_fit_params(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:3) = temp.single_gaussian_fit_params;
            post_run_analysis.single_gaussian_theory_values(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:length(post_run_params.analysis.bin_edges)-1) = ...
                                                                        temp.single_gaussian_theory_values;
            post_run_analysis.single_gaussian_fit_error(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.single_gaussian_fit_error;
            post_run_analysis.sign_of_bistability(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.double_gaussian_existence;

            if temp.double_gaussian_existence == 1
                if post_run_params.analysis.save_RTS_PSD_extended_data
                    post_run_analysis.RTS_PSD.freqs(m_power, m_flux, m_gate, m_detuning, m_repetition, 1:length(temp.freqs)) = temp.freqs;
                    post_run_analysis.RTS_PSD.psd(m_power, m_flux, m_gate, m_detuning, m_repetition,  1:length(temp.freqs)) = temp.psd;
                    post_run_analysis.RTS_PSD.psd_dBm(m_power, m_flux, m_gate, m_detuning, m_repetition,  1:length(temp.freqs)) = temp.psd_dBm;
        %             post_run_analysis.RTS_PSD.theory_lorentzian_values(m_power, m_flux, m_gate, m_detuning, m_repetition,  1:length(temp.freqs)) = temp.theory_lorentzian;
                end
    %             post_run_analysis.RTS_PSD.lorentzian_fit_theory(m_power, m_flux, m_gate, m_detuning, m_repetition,  1:length(temp.freqs)) = temp.theory_lorentzian_fit;
                post_run_analysis.RTS_PSD_fits.lorentzian_fit_lifetime_state_1(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.lifetime_state_1_lorentz_fit;
                post_run_analysis.RTS_PSD_fits.lorentzian_fit_lifetime_state_2(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.lifetime_state_2_lorentz_fit;
                post_run_analysis.RTS_PSD_fits.lorentzian_fit_amp_diff(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.amp_diff_lorentz_fit;
                post_run_analysis.RTS_PSD_fits.lorentzian_fit_err(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.lorentz_fit_err;
            end

            %%%% store necessary time data, delete rest
            if post_run_params.analysis.storing_time_for_RTS ~= 0 && post_run_params.analysis.save_RTS_PSD_extended_data
                input_params.start_index_of_RTS_raw_data_to_store = input_params.start_time_of_RTS_raw_data_to_store * input_params.digitizer.sample_rate;
                input_params.length_of_RTS_raw_data_to_store = input_params.time_length_of_RTS_raw_data_to_store * input_params.digitizer.sample_rate; 
                if input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store > length(temp.raw_data_out)
                    input_params.start_index_of_RTS_raw_data_to_store = length(temp.raw_data_out) - input_params.length_of_RTS_raw_data_to_store - 1;
                end

                post_run_analysis.RTS.moving_mean_average_phase(m_power, m_flux, m_gate, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
                    temp.raw_data_out(round(input_params.start_index_of_RTS_raw_data_to_store) : round(input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1));

                post_run_analysis.RTS.time(m_power, m_flux, m_gate, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...    
                    raw_data.time_corrected(round(input_params.start_index_of_RTS_raw_data_to_store) : round(input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1));

                post_run_analysis.RTS.raw_phase(m_power, m_flux, m_gate, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
                    raw_data.phase_extracted(round(input_params.start_index_of_RTS_raw_data_to_store) : round(input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1));

                post_run_analysis.RTS.raw_amp(m_power, m_flux, m_gate, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
                    raw_data.amp_extracted(round(input_params.start_index_of_RTS_raw_data_to_store) : round(input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1));

                post_run_analysis.RTS.moving_mean_average_amp(m_power, m_flux, m_gate, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
                    raw_data.amp_moving_mean(round(input_params.start_index_of_RTS_raw_data_to_store) : round(input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1));

                post_run_analysis.RTS.clean_time_data(m_power, m_flux, m_gate, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
                    temp.clean_time_data(round(input_params.start_index_of_RTS_raw_data_to_store) : round(input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1));

                post_run_analysis.RTS.clean_RTS_phase(m_power, m_flux, m_gate, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
                    temp.clean_RTS_data(round(input_params.start_index_of_RTS_raw_data_to_store) : round(input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1));

                post_run_analysis.RTS.simple_threshold_clean_RTS_data(m_power, m_flux, m_gate, m_detuning, m_repetition, 1 : input_params.length_of_RTS_raw_data_to_store) = ...
                    temp.simple_threshold_clean_RTS_data(round(input_params.start_index_of_RTS_raw_data_to_store) : round(input_params.start_index_of_RTS_raw_data_to_store + input_params.length_of_RTS_raw_data_to_store - 1));
            end

            close all     
            post_run_analysis.analysis.moving_mean_average_time(m_power, m_flux, m_gate, m_detuning, m_repetition) = post_run_params.analysis.moving_mean_average_time;
            post_run_analysis.analysis.bin_edges(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = post_run_params.analysis.bin_edges;
            %% Fit Poissonian
            post_run_analysis.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition) = 0; %%% initiate fit success at 0.
            %%%%% if conditions to only fit poissonian if bistability exists.
            if post_run_params.analysis.current_run_bistability_existence == 1
                disp(['bistability detected, fitting Poissonian' 13 10])
                %%%% if conditions to analyze according to chosen poisson fitting method. averaged and separate are straight forward. 
                %%%% histogrammed together and separate_and_together are a little involved to cover all failure modes
                if strcmp(post_run_params.poissonian_lifetime_repetitions_mode, 'separate') || ...
                        strcmp(post_run_params.poissonian_lifetime_repetitions_mode, 'averaged') || ...
                        (strcmp(post_run_params.poissonian_lifetime_repetitions_mode, 'histogrammed_together') && m_repetition == 1)|| ...
                        (strcmp(post_run_params.poissonian_lifetime_repetitions_mode, 'histogrammed_together') && m_repetition > 1 && ...
                        post_run_analysis.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition - 1) == 0)
                    [temp.poisson_lifetime_1_us, temp.poisson_lifetime_2_us, temp.error_poisson_lifetime_1_us, temp.error_poisson_lifetime_2_us, ...
                        temp.poisson_theory_1, temp.poisson_theory_2, temp.switch_time_bin_centers_1, temp.hist_count_1, temp.switch_time_bin_centers_2, ...
                        temp.hist_count_2, temp.fit_success, temp.fit_flag] = extract_poissonian_lifetimes(temp.clean_time_data, temp.clean_RTS_data, temp.gaussian_1_mean, temp.gaussian_2_mean, ...
                        post_run_params.minimum_number_switches, post_run_params.poissonian_fit_bin_number);
                    if ~temp.fit_success
                       analysis.sign_of_bistability(m_power, m_flux, m_gate, m_detuning, m_repetition) = 0;
                    end
                elseif strcmp(post_run_params.poissonian_lifetime_repetitions_mode, 'histogrammed_together') && m_repetition > 1
                    [temp.poisson_lifetime_1_us, temp.poisson_lifetime_2_us, temp.error_poisson_lifetime_1_us, temp.error_poisson_lifetime_2_us, ...
                        temp.poisson_theory_1, temp.poisson_theory_2, temp.switch_time_bin_centers_1, temp.hist_count_1, temp.switch_time_bin_centers_2, ...
                        temp.hist_count_2, temp.fit_success, temp.fit_flag] = extract_poissonian_lifetimes(temp.clean_time_data, temp.clean_RTS_data, temp.gaussian_1_mean, temp.gaussian_2_mean, ...
                        post_run_params.minimum_number_switches, [], squeeze(post_run_analysis.Poissonian.hist_count_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)),  ...
                        squeeze(post_run_analysis.Poissonian.hist_count_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)), ...
                        squeeze(post_run_analysis.Poissonian.switch_time_bin_centers_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)), ...
                        squeeze(post_run_analysis.Poissonian.switch_time_bin_centers_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)));
                    if ~temp.fit_success
                       analysis.sign_of_bistability(m_power, m_flux, m_gate, m_detuning, m_repetition) = 0;
                    end
                end
                
                %%%% for separate and together - first part for separate, same as usual, second part for histogramming together
                if strcmp(post_run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together') 
                    [temp.poisson_lifetime_1_us, temp.poisson_lifetime_2_us, temp.error_poisson_lifetime_1_us, temp.error_poisson_lifetime_2_us, ...
                        temp.poisson_theory_1, temp.poisson_theory_2, temp.switch_time_bin_centers_1, temp.hist_count_1, temp.switch_time_bin_centers_2, ...
                        temp.hist_count_2, temp.fit_success, temp.fit_flag] = extract_poissonian_lifetimes(temp.clean_time_data, temp.clean_RTS_data, temp.gaussian_1_mean, ...
                        temp.gaussian_2_mean, post_run_params.minimum_number_switches, post_run_params.poissonian_fit_bin_number);
                    if ~temp.fit_success
                       analysis.sign_of_bistability(m_power, m_flux, m_gate, m_detuning, m_repetition) = 0;
                    end
                    if m_repetition == 1 || (m_repetition > 1 && ...
                                post_run_analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition - 1) == 0)
                        temp.hist_together.poisson_lifetime_1_us = temp.poisson_lifetime_1_us;
                        temp.hist_together.poisson_lifetime_2_us = temp.poisson_lifetime_2_us;
                        temp.hist_together.error_poisson_lifetime_1_us = temp.error_poisson_lifetime_1_us;
                        temp.hist_together.error_poisson_lifetime_2_us = temp.error_poisson_lifetime_2_us;
                        temp.hist_together.poisson_theory_1 = temp.poisson_theory_1;
                        temp.hist_together.poisson_theory_2 = temp.poisson_theory_2;
                        temp.hist_together.switch_time_bin_centers_1 = temp.switch_time_bin_centers_1;
                        temp.hist_together.hist_count_1 = temp.hist_count_1;
                        temp.hist_together.switch_time_bin_centers_2 = temp.switch_time_bin_centers_2;
                        temp.hist_together.hist_count_2 = temp.hist_count_2;
                        temp.hist_together.fit_success = temp.fit_success;
                        temp.hist_together.fit_flag= temp.fit_flag;
                    elseif m_repetition > 1                    
                        [temp.hist_together.poisson_lifetime_1_us, temp.hist_together.poisson_lifetime_2_us, temp.hist_together.error_poisson_lifetime_1_us, ...
                            temp.hist_together.error_poisson_lifetime_2_us, temp.hist_together.poisson_theory_1, temp.hist_together.poisson_theory_2, ...
                            temp.hist_together.switch_time_bin_centers_1, temp.hist_together.hist_count_1, temp.hist_together.switch_time_bin_centers_2, ...
                            temp.hist_together.hist_count_2, temp.hist_together.fit_success, temp.hist_together.fit_flag] = extract_poissonian_lifetimes(temp.clean_time_data, temp.clean_RTS_data, ...
                            temp.gaussian_1_mean, temp.gaussian_2_mean, post_run_params.minimum_number_switches, [], ...
                            squeeze(post_run_analysis.hist_together.Poissonian.hist_count_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)),  ...
                            squeeze(post_run_analysis.hist_together.Poissonian.hist_count_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)), ...
                            squeeze(post_run_analysis.hist_together.Poissonian.switch_time_bin_centers_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)), ...
                            squeeze(post_run_analysis.hist_together.Poissonian.switch_time_bin_centers_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)));
                    end
                end
                %%%% if not enough switching events to fit poissonian, allocate 0s                
            else
                temp.poisson_lifetime_1_us = NaN;
                temp.poisson_lifetime_2_us = NaN;
                temp.error_poisson_lifetime_1_us = NaN;
                temp.error_poisson_lifetime_2_us = NaN;
                temp.poisson_theory_1 = zeros(1, post_run_params.poissonian_fit_bin_number);
                temp.poisson_theory_2 = zeros(1, post_run_params.poissonian_fit_bin_number);
                post_run_params.Poisson_fig_plot_param = 0;
                temp.switch_time_bin_centers_1 = zeros(1, post_run_params.poissonian_fit_bin_number);
                temp.hist_count_1 = zeros(1, post_run_params.poissonian_fit_bin_number);
                temp.switch_time_bin_centers_2 = zeros(1, post_run_params.poissonian_fit_bin_number);
                temp.hist_count_2 = zeros(1, post_run_params.poissonian_fit_bin_number);
                temp.fit_success = 0;
                temp.fit_flag = 'lack of bistability from Gaussians';
                if (strcmp(post_run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together') && m_repetition == 1) || ...
                        (m_repetition > 1 && sum(squeeze(post_run_analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, :))) == 0)
                    temp.hist_together.poisson_lifetime_1_us = NaN;
                    temp.hist_together.poisson_lifetime_2_us = NaN;
                    temp.hist_together.error_poisson_lifetime_1_us = NaN;
                    temp.hist_together.error_poisson_lifetime_2_us = NaN;
                    temp.hist_together.poisson_theory_1 = zeros(1, post_run_params.poissonian_fit_bin_number);
                    temp.hist_together.poisson_theory_2 = zeros(1, post_run_params.poissonian_fit_bin_number);
                    temp.hist_together.switch_time_bin_centers_1 = zeros(1, post_run_params.poissonian_fit_bin_number);
                    temp.hist_together.hist_count_1 = zeros(1, post_run_params.poissonian_fit_bin_number);
                    temp.hist_together.switch_time_bin_centers_2 = zeros(1, post_run_params.poissonian_fit_bin_number);
                    temp.hist_together.hist_count_2 = zeros(1, post_run_params.poissonian_fit_bin_number);
                    temp.hist_together.fit_success = 0;
                    temp.hist_together.fit_flag = 'lack of bistability from Gaussians';
                elseif (m_repetition > 1 && sum(squeeze(post_run_analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, :))) ~= 0)
                    temp.hist_together.poisson_lifetime_1_us = post_run_analysis.hist_together.Poissonian.poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition - 1);
                    temp.hist_together.poisson_lifetime_2_us = post_run_analysis.hist_together.Poissonian.poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning, m_repetition - 1);
                    temp.hist_together.error_poisson_lifetime_1_us = post_run_analysis.hist_together.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition - 1);
                    temp.hist_together.error_poisson_lifetime_2_us = post_run_analysis.hist_together.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition - 1);
                    temp.hist_together.poisson_theory_1 = post_run_analysis.hist_together.Poissonian.poisson_theory_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :);
                    temp.hist_together.poisson_theory_2 =  post_run_analysis.hist_together.Poissonian.poisson_theory_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :);
                    temp.hist_together.switch_time_bin_centers_1 = post_run_analysis.hist_together.switch_time_bin_centers_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :);
                    temp.hist_together.hist_count_1 = post_run_analysis.hist_together.Poissonian.hist_count_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :);
                    temp.hist_together.switch_time_bin_centers_2 = post_run_analysis.hist_together.switch_time_bin_centers_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :);
                    temp.hist_together.hist_count_2 = post_run_analysis.hist_together.Poissonian.hist_count_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :);
                    temp.hist_together.fit_success = post_run_analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition - 1);
                    temp.hist_together.fit_flag = 'lack of bistability from Gaussians';
                end
            end
            post_run_params.Poisson_fig_plot_param = temp.fit_success;
            
            post_run_analysis.analysis.current_run_bistability_existence (m_power, m_flux, m_gate, m_repetition) = post_run_params.analysis.current_run_bistability_existence;
            post_run_analysis.analysis.poissonian_fit_bin_number(m_power, m_flux, m_gate, m_detuning) = post_run_params.poissonian_fit_bin_number;
            post_run_analysis.Poissonian.lifetime_1(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.poisson_lifetime_1_us;
            post_run_analysis.Poissonian.lifetime_2(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.poisson_lifetime_2_us;
            post_run_analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.error_poisson_lifetime_1_us;
            post_run_analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.error_poisson_lifetime_2_us;
            post_run_analysis.Poissonian.switch_time_bin_centers_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.switch_time_bin_centers_1;
            post_run_analysis.Poissonian.switch_time_bin_centers_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.switch_time_bin_centers_2;
            post_run_analysis.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.fit_success;
            post_run_analysis.Poissonian.flag{m_power, m_flux, m_gate, m_detuning, m_repetition} = temp.fit_flag;
            
            post_run_analysis.Poissonian.hist_count_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_count_1;

            post_run_analysis.Poissonian.hist_count_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_count_2;

            post_run_analysis.Poissonian.poisson_theory_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.poisson_theory_1(:);

            post_run_analysis.Poissonian.poisson_theory_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.poisson_theory_2(:);
            
            if strcmp(post_run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together')
                    
                post_run_analysis.hist_together.Poissonian.poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.hist_together.poisson_lifetime_1_us;
                post_run_analysis.hist_together.Poissonian.poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.hist_together.poisson_lifetime_2_us;
                post_run_analysis.hist_together.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.hist_together.error_poisson_lifetime_1_us;
                post_run_analysis.hist_together.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.hist_together.error_poisson_lifetime_2_us;
                post_run_analysis.hist_together.switch_time_bin_centers_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.switch_time_bin_centers_1;
                post_run_analysis.hist_together.switch_time_bin_centers_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.switch_time_bin_centers_2;
                
                post_run_analysis.hist_together.Poissonian.hist_count_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.hist_count_1 (:);
                
                post_run_analysis.hist_together.Poissonian.hist_count_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.hist_count_2(:);

                post_run_analysis.hist_together.Poissonian.poisson_theory_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.poisson_theory_1 (:);

                post_run_analysis.hist_together.Poissonian.poisson_theory_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.poisson_theory_2(:);
                
                post_run_analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.hist_together.fit_success;
                
                post_run_analysis.hist_together.Poissonian.flag{m_power, m_flux, m_gate, m_detuning, m_repetition} = temp.hist_together.fit_flag;    
            end
            post_run_analysis.poissonian_lifetime_repetitions_mode{m_power, m_flux, m_gate, m_detuning} = post_run_params.poissonian_lifetime_repetitions_mode;
            %% Plot Poissonian
            if post_run_params.analysis.current_run_bistability_existence && post_run_params.Poisson_fig_plot_param 
                if post_run_params.plot_visible == 1 
                    Poissonian_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
                elseif post_run_params.plot_visible == 0 
                    Poissonian_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
                end

                bar(temp.switch_time_bin_centers_1*1e6, log(temp.hist_count_1), 'r', 'FaceAlpha', 0.25, 'DisplayName', 'State 1 hist')
                hold on
                bar(temp.switch_time_bin_centers_2*1e6, log(temp.hist_count_2), 'b', 'FaceAlpha', 0.25, 'DisplayName', 'State 2 hist')
                plot(temp.switch_time_bin_centers_1*1e6, temp.poisson_theory_1, 'r', 'linewidth', 2, 'DisplayName', 'State 1 fit')
                plot(temp.switch_time_bin_centers_2*1e6, temp.poisson_theory_2, 'b', 'linewidth', 2, 'DisplayName', 'State 2 fit')
                xlabel('Switching time ($\mu$s)', 'interpreter', 'latex')
                ylabel('log(Count)', 'interpreter', 'latex')
                title(['Poisson fit for P$_{\mathrm{in}}$ = ' num2str(input_params.input_power_value_list(m_power)) 'dBm' 13 10 ...
                    '$n_g = $' num2str(input_params.ng_1_value_list(m_gate)) ', $\Phi_{\mathrm{ext}}$ = ' num2str(input_params.flux_1_value_list(m_flux)) '$\Phi_0$' 13 10 ...
                    '$\Delta$ = ' num2str(detuning_point) 'MHz' ], 'interpreter', 'latex')
                legend show
                annotation('textbox', [0.67, 0.33, 0.55, 0.3], 'String', ['Lifetime state 1 = ' 13 10 num2str(round(temp.poisson_lifetime_1_us, 2)) ...
                    '$\pm$' num2str(round(temp.error_poisson_lifetime_1_us, 2)) '$ \mu$s'], 'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'r')
                annotation('textbox', [0.67, 0.23, 0.55, 0.3], 'String', ['Lifetime state 2 = ' 13 10 num2str(round(temp.poisson_lifetime_2_us, 2)) ...
                    '$\pm$' num2str(round(temp.error_poisson_lifetime_1_us, 2)) '$ \mu$s'], 'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'b')
                annotation('textbox', [0.35, 0.45, 0.5, 0.3], 'String', ['Total counts = ' num2str(sum(temp.hist_count_1))], ...
                    'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'r')
                annotation('textbox', [0.35, 0.5, 0.5, 0.3], 'String', ['Total counts = ' num2str(sum(temp.hist_count_2))], ...
                    'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'b')

                if post_run_params.save_png_param == 1
                        save_file_name = [post_run_params.rts_fig_directory  num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) '_' ...
                            num2str(m_detuning) '_' num2str(m_repetition)...
                            '_ng_' num2str(input_params.ng_1_value_list(m_gate)) '_flux_' num2str(input_params.flux_1_value_list(m_flux)*1000) ...
                            'm_detuning_' num2str(detuning_point) 'MHz_poisson_fit.png'];
                        saveas(Poissonian_figure, save_file_name)
                end
                if post_run_params.save_fig_file_param
                        save_file_name = [post_run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) ...
                            '_' num2str(m_detuning) '_' num2str(m_repetition)...
                            '_ng_' num2str(input_params.ng_1_value_list(m_gate)) '_flux_' num2str(input_params.flux_1_value_list(m_flux)*1000) ...
                            'm_detuning_' num2str(detuning_point) 'MHz_poisson_fit.fig'];
                        saveas(Poissonian_figure, save_file_name)
                end
                clear Poissonian_figure ...
                      save_file_name
            end
            post_run_analysis.analyzed_parameter(m_power, m_flux, m_gate, m_detuning, m_repetition) = 1;
            close all
            %% Plot Poissonian of together if histogrammed together and separately
            if post_run_params.analysis.current_run_bistability_existence && ...
                    strcmp(post_run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together') && ...
                    m_repetition == squeeze(data.repetition_number(m_power, m_flux, m_gate, m_detuning))
                if post_run_analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, squeeze(data.repetition_number(m_power, m_flux, m_gate, m_detuning))) 
                    if post_run_params.plot_visible == 1 
                        Poissonian_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
                    elseif post_run_params.plot_visible == 0 
                        Poissonian_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
                    end
    
                    bar(temp.hist_together.switch_time_bin_centers_1*1e6, log(temp.hist_together.hist_count_1), 'r', 'FaceAlpha', 0.25, 'DisplayName', 'State 1 hist')
                    hold on
                    bar(temp.hist_together.switch_time_bin_centers_2*1e6, log(temp.hist_together.hist_count_2), 'b', 'FaceAlpha', 0.25, 'DisplayName', 'State 2 hist')
                    plot(temp.hist_together.switch_time_bin_centers_1*1e6, temp.hist_together.poisson_theory_1, 'r', 'linewidth', 2, 'DisplayName', 'State 1 fit')
                    plot(temp.hist_together.switch_time_bin_centers_2*1e6, temp.hist_together.poisson_theory_2, 'b', 'linewidth', 2, 'DisplayName', 'State 2 fit')
                    xlabel('Switching time ($\mu$s)', 'interpreter', 'latex')
                    ylabel('log(Count)', 'interpreter', 'latex')
                    title(['Poisson fit histogrammed over repetitions for P$_{\mathrm{in}}$ = ' num2str(input_params.input_power_value_list(m_power)) 'dBm' 13 10 ...
                        '$n_g = $' num2str(input_params.ng_1_value_list(m_gate)) ', $\Phi_{\mathrm{ext}}$ = ' num2str(input_params.flux_1_value_list(m_flux)) '$\Phi_0$' 13 10 ...
                        '$\Delta$ = ' num2str(detuning_point) 'MHz' ], 'interpreter', 'latex')
                    legend show
                    annotation('textbox', [0.55, 0.45, 0.5, 0.3], 'String', ['Lifetime state 1 = ' num2str(round(temp.hist_together.poisson_lifetime_1_us, 2)) ...
                        '$\pm$' num2str(round(temp.hist_together.error_poisson_lifetime_1_us, 2)) '$ \mu$s'], 'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'r')
                    annotation('textbox', [0.55, 0.35, 0.5, 0.3], 'String', ['Lifetime state 2 = ' num2str(round(temp.hist_together.poisson_lifetime_2_us, 2)) ...
                        '$\pm$' num2str(round(temp.hist_together.error_poisson_lifetime_1_us, 2)) '$ \mu$s'], 'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'b')
                    annotation('textbox', [0.35, 0.2, 0.5, 0.3], 'String', ['Total counts = ' num2str(sum(temp.hist_together.hist_count_1))], ...
                        'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'r')
                    annotation('textbox', [0.35, 0.25, 0.5, 0.3], 'String', ['Total counts = ' num2str(sum(temp.hist_together.hist_count_2))], ...
                        'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'b')
    
                    if post_run_params.save_png_param == 1
                        save_file_name = [post_run_params.rts_fig_directory  num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning)...
                            '_ng_' num2str(input_params.ng_1_value_list(m_gate)) '_flux_' ...
                            num2str(input_params.flux_1_value_list(m_flux)*1000) ...
                            'm_detuning_' num2str(detuning_point) 'MHz_poisson_hist_together_fit.png'];
                        saveas(Poissonian_figure, save_file_name)
                    end
                    if post_run_params.save_fig_file_param == 1
                        save_file_name = [post_run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning)...
                            '_ng_' num2str(input_params.ng_1_value_list(m_gate)) '_flux_' ...
                            num2str(input_params.flux_1_value_list(m_flux)*1000) 'm_detuning_' ...
                            num2str(detuning_point) 'MHz_poisson_hist_together_.fig'];
                        saveas(Poissonian_figure, save_file_name)
                    end
                    clear Poissonian_figure ...
                          save_file_name
    
                    clear moving_mean_average_time ...
                          moving_mean_average_number ...
                          raw_data ...
                          temp ... 
                          detuning_point 
                end
            end
        end
    end
    clear m_bias_point ...
          m_data_counter ...
          m_detuning ...
          m_flux ...
          m_gate ...
          m_power ...
          m_record_count ...
          m_repetition ...
          moving_mean_average_number ...
          moving_mean_average_time ...
          raw_data_matrix
    if post_run_params.save_data_param
        save_file_name = strtrim(temp_filelist.file_name);
        disp(['saving ' save_file_name])
        movefile([post_run_params.directory_to_be_analyzed '\' temp_filelist.file_name],[post_run_params.directory_to_be_analyzed '\' ...
            save_file_name(1 : end -4) '_analyzed.mat'])
        clear save_file_name
    end
    %% save post run analysis to switching finder comprehensive mat file
    if post_run_params.save_data_param
        disp('saving comprehensive data')
        save(post_run_params.file_to_load_input_params_from,'post_run_params', 'post_run_analysis', '-append')
        save(post_run_params.file_to_save_post_run_analysis_separately,'post_run_params', 'post_run_analysis', '-append')
        disp(['comprehensive data saved' 13 10 13 10])
    end
end
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

            % breaks execution of cleaning script if there are no signs of bistability
            if single_gaussian_fit_error < min(fit_error_360, fit_error_180) || single_gaussian_fit_params(3) == 0 || ...
                        (double_gaussian_fit_360(2) == double_gaussian_fit_360(5) && fit_error_360 < fit_error_180) || ...
                        (double_gaussian_fit_180(2) == double_gaussian_fit_180(5) && fit_error_180 < fit_error_360) 
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
%% Function extract Poissonian lifetimes
function [lifetime_1_us, lifetime_2_us, std_exp_fit_state_1, std_exp_fit_state_2, theory_values_state_1, theory_values_state_2, time_bin_centers_state_1, lifetime_state_1_hist_data, ...
    time_bin_centers_state_2,  lifetime_state_2_hist_data, fit_success, flag] =  extract_poissonian_lifetimes(clean_time_data, clean_amp_data, gaussian_1_mean, gaussian_2_mean, min_switching_number, bin_number, hist_count_state_1, ...
                                        hist_count_state_2, bin_centers_state_1, bin_centers_state_2)

    clean_time_data = clean_time_data(:);
    clean_amp_data = clean_amp_data(:);
    if exist('hist_count_state_1', 'var')
        hist_count_state_1 = hist_count_state_1(:);
        hist_count_state_2 = hist_count_state_2(:);
        bin_centers_state_1 = bin_centers_state_1(:);
        bin_centers_state_2 = bin_centers_state_2(:);
    end
    if ~exist('bin_number', 'var') && ~exist('bin_centers', 'var') && ~exist('hist_state_1', 'var') && ~exist('hist_state_2', 'var')
        bin_number = 25;
        bin_centers_state_1 = [];
        bin_centers_state_2 = [];
        hist_count_state_1 = [];
        hist_count_state_2 = [];
    end
    at_least_so_many_counts = 20; % has to have at least 2 bins with so many counts. if not, reject poisson fit
    
    %%%% figures out when the clean_RTS_noise_broadening function starts
    %%%% spitting out 0 and 1 states it is sure about. 
    first_sure_time_state_1 = clean_time_data(clean_amp_data == gaussian_1_mean);
    if ~isempty(first_sure_time_state_1)
        first_sure_time_state_1 = first_sure_time_state_1(1);
    end
    
    first_sure_time_state_2 = clean_time_data(clean_amp_data == gaussian_2_mean);
    if ~isempty(first_sure_time_state_2) 
        first_sure_time_state_2 = first_sure_time_state_2(1);
    end
    
    if isempty(first_sure_time_state_1) || isempty(first_sure_time_state_2)
        lifetime_1_us = NaN; 
        lifetime_2_us = NaN;
        std_exp_fit_state_1 = NaN;
        std_exp_fit_state_2 = NaN;
        theory_values_state_1 = NaN;
        theory_values_state_2 = NaN;
        time_bin_centers_state_1 = NaN;
        time_bin_centers_state_2 = NaN;
        lifetime_state_1_hist_data = NaN;
        lifetime_state_2_hist_data = NaN;
        fit_success = 0;
        flag = '1st sure state undetermined';        
        return
    end
    
    if first_sure_time_state_1 < first_sure_time_state_2
        analysis_time_data = clean_time_data(clean_time_data > first_sure_time_state_1);
        analysis_amp_data = clean_amp_data(clean_time_data > first_sure_time_state_1);
    else
        analysis_time_data = clean_time_data(clean_time_data > first_sure_time_state_2);
        analysis_amp_data = clean_amp_data(clean_time_data > first_sure_time_state_2);
    end
%%%%%%%%%%%%%

%%%%%%% assign +1 and -1 to states that are definitely known
    states = zeros(size(analysis_amp_data));
    states(analysis_amp_data == gaussian_1_mean) = 1;
    states(analysis_amp_data == gaussian_2_mean) = -1;
%%%%%%%%%%%%%%%%%%%%%    

%%%%%%%% calculate time points at which state switches
    switching_points = analysis_time_data(diff(states) ~= 0);
    if length(switching_points) < min_switching_number
        lifetime_1_us = 0;
        lifetime_2_us = 0;
        std_exp_fit_state_1 = 0;
        std_exp_fit_state_2 = 0;
        theory_values_state_1 = NaN;
        theory_values_state_2 = NaN;
        time_bin_centers_state_1 = NaN;
        time_bin_centers_state_2 = NaN;
        lifetime_state_1_hist_data = NaN;
        lifetime_state_2_hist_data = NaN;
        fit_success = 0;
        flag = ['fewer than ' num2str(min_switching_number) ' switches in run'];        
        return
    end
%%%% calculate time since the last switch, assign as the time in corresponding state     
    lifetime_both_states = diff(switching_points);
    if states(1) == 1
        lifetime_state_1_array = lifetime_both_states(1:2:end);
        lifetime_state_2_array = lifetime_both_states(2:2:end);
    elseif states(1) == -1
        lifetime_state_1_array = lifetime_both_states(2:2:end);
        lifetime_state_2_array = lifetime_both_states(1:2:end);
    end
%%%%%%%%%%%%%%%%%%%%%    
    
%%%%%%% calculate histograms of the switching times
    if isempty(bin_number)
        [lifetime_state_1_hist_data, time_bin_centers_state_1] = hist(lifetime_state_1_array, bin_centers_state_1 );
        [lifetime_state_2_hist_data, time_bin_centers_state_2] = hist(lifetime_state_2_array, bin_centers_state_2);
        lifetime_state_1_hist_data = lifetime_state_1_hist_data(:) + hist_count_state_1(:);
        lifetime_state_2_hist_data = lifetime_state_2_hist_data(:) + hist_count_state_2(:);
    else
        [lifetime_state_1_hist_data, time_bin_centers_state_1] = hist(lifetime_state_1_array, bin_number);
        [lifetime_state_2_hist_data, time_bin_centers_state_2] = hist(lifetime_state_2_array, bin_number);
    end
%     
%     time_bin_centers_state_1(lifetime_state_1_hist_data < 5) = NaN;
%     lifetime_state_1_hist_data(lifetime_state_1_hist_data < 5) = NaN;
%     time_bin_centers_state_2(lifetime_state_2_hist_data < 5) = NaN;
%     lifetime_state_2_hist_data(lifetime_state_2_hist_data < 5) = NaN;
%     figure
%     bar(time_bin_centers_state_1(lifetime_state_1_hist_data > 5)*1e6, log(lifetime_state_1_hist_data(lifetime_state_1_hist_data > 5)))
%     hold on
%     bar(time_bin_centers_state_2(lifetime_state_1_hist_data > 5)*1e6, log(lifetime_state_2_hist_data(lifetime_state_1_hist_data > 5)))
    if length(lifetime_state_1_hist_data(lifetime_state_1_hist_data > at_least_so_many_counts)) < 4 || length(lifetime_state_2_hist_data(lifetime_state_2_hist_data > at_least_so_many_counts)) < 4
        lifetime_1_us = 0;
        lifetime_2_us = 0;
        std_exp_fit_state_1 = 0;
        std_exp_fit_state_2 = 0;
        theory_values_state_1 = NaN;
        theory_values_state_2 = NaN;
        lifetime_state_1_hist_data = NaN;
        lifetime_state_2_hist_data = NaN;
        fit_success = 0;
        flag = '< 4 bins with at least 20 counts';
        return
    end
%%%%% fit straight line to log(hist_count) vs time. (see Staumbaugh PRB 2007)    
    fit_state_1 = polyfitn(time_bin_centers_state_1(lifetime_state_1_hist_data > 5)*1e6, log(lifetime_state_1_hist_data(lifetime_state_1_hist_data > 5)),1);
    fit_state_2 = polyfitn(time_bin_centers_state_2(lifetime_state_2_hist_data > 5)*1e6, log(lifetime_state_2_hist_data(lifetime_state_2_hist_data > 5)),1);

%%%%%% slope of line is switching rate out of corresponding state %%%%%%%%    
    exp_fit_state_1 = fit_state_1.Coefficients;
    exp_fit_state_2 = fit_state_2.Coefficients;

%%%%% average lifetime is inverse of switching rate    
    lifetime_1_us = -1*(1/exp_fit_state_1(1));
    lifetime_2_us = -1*(1/exp_fit_state_2(1));

%%%%% switching time error calculated by polyfitn  function %%%%%     
    switching_rate_state_1_parameter_error = fit_state_1.ParameterStd(1);
    switching_rate_state_2_parameter_error = fit_state_2.ParameterStd(1);
    
%%%% standard deviation of inverse function - see
%%%% https://en.wikipedia.org/wiki/Propagation_of_uncertainty
%%%% example formulae table
    std_exp_fit_state_1 = abs(switching_rate_state_1_parameter_error*lifetime_1_us^2);
    std_exp_fit_state_2 = abs(switching_rate_state_2_parameter_error*lifetime_2_us^2);
    
%     %%%% incorrect SD of average lifetime calculation %%%%
   %%%% actually, turns out that this is also quite alright. this is the
   %%%% same as the wiki one where the wiki has also assumed that 
   %%%% the s.d << the mean
%     std_exp_fit_state_1 = [abs(1/exp_fit_state_1(1) - 1/(exp_fit_state_1(1) + switching_rate_state_1_parameter_error)), abs(1/exp_fit_state_1(1) - 1/(exp_fit_state_1(1) - switching_rate_state_1_parameter_error))];
%     std_exp_fit_state_2 = [abs(1/exp_fit_state_2(1) - 1/(exp_fit_state_2(1) + switching_rate_state_2_parameter_error)), abs(1/exp_fit_state_2(1) - 1/(exp_fit_state_2(1) - switching_rate_state_2_parameter_error))];

    
    theory_values_state_1 = polyval(exp_fit_state_1, time_bin_centers_state_1*1e6);
    theory_values_state_2 =  polyval(exp_fit_state_2, time_bin_centers_state_2*1e6);
    fit_success = 1;
    flag = 'success';
%     figure
%     bar(time_bin_centers_state_1*1e6, log(lifetime_state_1_hist_data))
%     hold on
%     plot(time_bin_centers_state_1*1e6, theory_values_state_1)
%     bar(time_bin_centers_state_2*1e6, log(lifetime_state_2_hist_data))
%     plot(time_bin_centers_state_2*1e6, theory_values_state_2)
%     xlabel('Switching time (\mus)')
%     ylabel('log(count)')
        
end        