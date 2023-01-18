plotting.plot_visible = 1;
plotting.save_data_and_png_param = 0;
plotting.cutoff_error = 400; % in us, is the error above which a datapoint is not plotted
plotting.poissonian_lifetime_repetitions_mode = 'separate_and_together'; % separate, or averaged. analysis with histogrammed together boils down to separate too
plotting.detunings_or_drive_freq = 'drive_freq'; % 'detunings' or 'drive_freq'
plotting.power_start_index = 1;
plotting.power_step_index = 1;
plotting.power_stop_index = 1;
plotting.gate_start_index = 1;
plotting.gate_step_index = 1;
plotting.gate_stop_index = 8;
plotting.flux_start_index = 1;
plotting.flux_step_index = 1;
plotting.flux_stop_index = 4;
plotting.sort_by = 'kerr'; % 'gate', 'flux', 'power', 'kerr'

if strcmp(plotting.sort_by, 'gate')
    colors = parula(length(plotting.gate_start_index:plotting.gate_step_index:plotting.gate_stop_index));
elseif strcmp(plotting.sort_by, 'flux')
    colors = parula(length(plotting.flux_start_index:plotting.flux_step_index:plotting.flux_stop_index));
elseif strcmp(plotting.sort_by, 'kerr')
    colors = parula(length(plotting.flux_start_index:plotting.flux_step_index:plotting.flux_stop_index) * ...
        length(plotting.gate_start_index:plotting.gate_step_index:plotting.gate_stop_index));
    for m_flux = plotting.flux_start_index : plotting.flux_step_index : plotting.flux_stop_index
        for m_gate = plotting.gate_start_index:plotting.gate_step_index:plotting.gate_stop_index
            plotting.kerr_MHz(m_flux, m_gate) = find_kerr_MHz_ng_flux(input_params.ng_1_value_list(m_gate), input_params.flux_1_value_list(m_flux));
        end
    end
    [plotting.sorted_kerr_MHz, plotting.sorted_indices] = sort(plotting.kerr_MHz(:));
    colors = colors(plotting.sorted_indices, :);
end
%% Plot lifetime curves
for m_power = plotting.power_start_index : plotting.power_step_index : plotting.power_stop_index
    if plotting.plot_visible
        Lifetime_detuning_plots = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    elseif ~plotting.plot_visible
        Lifetime_detuning_plots = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
    end
    for m_flux = plotting.flux_start_index : plotting.flux_step_index : plotting.flux_stop_index
        if strcmp(plotting.sort_by, 'flux')
            color_setter = colors(m_flux, :);
        end
        for m_gate = plotting.gate_start_index : plotting.gate_step_index : plotting.gate_stop_index
            if strcmp(plotting.sort_by, 'gate')
                color_setter = colors(m_gate, :);
            elseif strcmp(plotting.sort_by, 'kerr')
                color_setter = colors((m_gate - 1) * length(plotting.flux_start_index:plotting.flux_step_index:plotting.flux_stop_index) + m_flux, :);
            end
            if strcmp(squeeze(post_run_analysis.poissonian_lifetime_repetitions_mode(m_power, m_flux, m_gate, 95)), 'separate_and_together') && m_flux == plotting.flux_start_index && ...
                    m_gate == plotting.gate_start_index && m_power == plotting.power_start_index
                user = input('both separate and together histogramming done. separate histograms plot separately(0) or averaged(1) or histogrammed together (2)?');
            end
            if strcmp(plotting.poissonian_lifetime_repetitions_mode, 'separate') || ...
                    (strcmp(squeeze(post_run_analysis.poissonian_lifetime_repetitions_mode(m_power, m_flux, m_gate, 95)), 'separate_and_together') && user == 0)
                hold on
                for m_repetition = 1 : input_params.number_repetitions
                    if strcmp(plotting.detunings_or_drive_freq, 'detunings')
                        temp.x_array = squeeze(data.detunings(m_power, m_flux, m_gate, :, m_repetition));
                        temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e6;
                    elseif strcmp(plotting.detunings_or_drive_freq, 'drive_freq')
                        temp.x_array = squeeze(data.drive_freq_GHz(m_power, m_flux, m_gate,:, m_repetition));
                        temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e9;
                    end
                    temp.y_array = squeeze(post_run_analysis.Poissonian.lifetime_1(m_power, m_flux, m_gate, :, m_repetition));
                    temp.y_error = squeeze(post_run_analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, :, m_repetition));
                    last_non_zero_detuning = find(temp.x_array ~=0);
                    last_non_zero_detuning = last_non_zero_detuning(end);
                    temp.x_array(last_non_zero_detuning + 1:end) = [];
                    temp.y_error(temp.y_array == 0) = [];
                    temp.x_error(last_non_zero_detuning + 1:end) = [];
                    temp.y_error(temp.y_array == 0) = [];
                    temp.x_error(temp.y_array == 0) = [];
                    temp.x_array(temp.y_array == 0) = [];
                    temp.y_array(temp.y_array == 0) = [];
                    %%% weed out lifetime fits with large errors
                    temp.x_error(temp.y_error >plotting.cutoff_error) = [];
                    temp.x_array(temp.y_error >plotting.cutoff_error) = [];
                    temp.y_array(temp.y_error >plotting.cutoff_error) = [];
                    temp.y_error(temp.y_error >plotting.cutoff_error) = [];
                    temp.x_error(isnan(temp.y_array)) = [];
                    temp.y_error(isnan(temp.y_array)) = [];
                    temp.x_array(isnan(temp.y_array)) = [];
                    temp.y_array(isnan(temp.y_array)) = [];


                    errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                    'x-', 'color', color_setter, 'Linewidth', 3, 'DisplayName', ['State 1, rep = ' num2str(m_repetition)]) 
                end

                for m_repetition = 1 : input_params.number_repetitions
                    if strcmp(plotting.detunings_or_drive_freq, 'detunings')
                        temp.x_array = squeeze(data.detunings(m_power, m_flux, m_gate, :, m_repetition));
                        temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e6;
                    elseif strcmp(plotting.detunings_or_drive_freq, 'drive_freq')
                        temp.x_array = squeeze(data.drive_freq_GHz(m_power, m_flux, m_gate, :, m_repetition));
                        temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e9;
                    end
                    temp.y_array = squeeze(post_run_analysis.Poissonian.lifetime_2(m_power, m_flux, m_gate, :, m_repetition));
                    temp.y_error = squeeze(post_run_analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, :, m_repetition));
                    last_non_zero_detuning = find(temp.x_array ~=0);
                    last_non_zero_detuning = last_non_zero_detuning(end);
                    temp.x_array(last_non_zero_detuning + 1:end) = [];
                    temp.x_error(last_non_zero_detuning + 1:end) = [];
                    temp.y_error(temp.y_array == 0) = [];
                    temp.x_error(temp.y_array == 0) = [];
                    temp.x_array(temp.y_array == 0) = [];
                    temp.y_array(temp.y_array == 0) = [];
                    %%% weed out lifetime fits with large errors
                    temp.x_error(temp.y_error >plotting.cutoff_error) = [];
                    temp.x_array(temp.y_error >plotting.cutoff_error) = [];
                    temp.y_array(temp.y_error >plotting.cutoff_error) = [];
                    temp.y_error(temp.y_error >plotting.cutoff_error) = [];
                    temp.x_error(isnan(temp.y_array)) = [];
                    temp.y_error(isnan(temp.y_array)) = [];
                    temp.x_array(isnan(temp.y_array)) = [];
                    temp.y_array(isnan(temp.y_array)) = [];


%                     errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
%                     'x--', 'color', color_setter, 'Linewidth', 3, 'DisplayName', ['State 2, rep = ' num2str(m_repetition), flux = ' num2str(input_params.flux_1_value_list(m_flux)) '\Phi_0, ' ...
%                 'n_g = ' num2str(input_params.ng_1_value_list(m_gate))])      
                end
            elseif strcmp(plotting.poissonian_lifetime_repetitions_mode, 'averaged') || ...
                    (strcmp(squeeze(post_run_analysis.poissonian_lifetime_repetitions_mode(m_power, m_flux, m_gate, 95)), 'separate_and_together') && user == 1)
                if strcmp(plotting.detunings_or_drive_freq, 'detunings')
                    temp.x_array = mean(squeeze(data.detunings(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e6;
                elseif strcmp(plotting.detunings_or_drive_freq, 'drive_freq')
                    temp.x_array = mean(squeeze(data.drive_freq_GHz(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e9;
                end
                temp.y_array = mean(squeeze(post_run_analysis.Poissonian.lifetime_1(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                temp.y_error = mean(squeeze(post_run_analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                last_non_zero_detuning = find(temp.x_array ~=0);
                last_non_zero_detuning = last_non_zero_detuning(end);
                temp.x_array(last_non_zero_detuning + 1:end) = [];
                temp.x_error(last_non_zero_detuning + 1:end) = [];
                temp.y_error(temp.y_array == 0) = [];
                temp.x_error(temp.y_array == 0) = [];
                temp.x_array(temp.y_array == 0) = [];
                temp.y_array(temp.y_array == 0) = [];
                %%% weed out lifetime fits with large errors
                temp.x_error(temp.y_error >plotting.cutoff_error) = [];
                temp.x_array(temp.y_error >plotting.cutoff_error) = [];
                temp.y_array(temp.y_error >plotting.cutoff_error) = [];
                temp.y_error(temp.y_error >plotting.cutoff_error) = [];
                temp.x_error(isnan(temp.y_array)) = [];
                temp.y_error(isnan(temp.y_array)) = [];
                temp.x_array(isnan(temp.y_array)) = [];
                temp.y_array(isnan(temp.y_array)) = [];
                
                
                errorbar(temp.x_array, temp.y_array,temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                    'x-', 'color', color_setter, 'Linewidth', 3, 'DisplayName', 'State 1 lifetimes')

                hold on

                if strcmp(plotting.detunings_or_drive_freq, 'detunings')
                    temp.x_array = mean(squeeze(data.detunings(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e6;
                elseif strcmp(plotting.detunings_or_drive_freq, 'drive_freq')
                    temp.x_array = mean(squeeze(data.drive_freq_GHz(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e9;
                end
                temp.y_array = mean(squeeze(post_run_analysis.Poissonian.lifetime_2(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                temp.y_error = mean(squeeze(post_run_analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                last_non_zero_detuning = find(temp.x_array ~=0);
                last_non_zero_detuning = last_non_zero_detuning(end);
                temp.x_array(last_non_zero_detuning + 1:end) = [];
                temp.x_error(last_non_zero_detuning + 1:end) = [];
                temp.y_error(temp.y_array == 0) = [];
                temp.x_error(temp.y_array == 0) = [];
                temp.x_array(temp.y_array == 0) = [];
                temp.y_array(temp.y_array == 0) = [];
                %%% weed out lifetime fits with large errors
                temp.x_error(temp.y_error >plotting.cutoff_error) = [];
                temp.x_array(temp.y_error >plotting.cutoff_error) = [];
                temp.y_array(temp.y_error >plotting.cutoff_error) = [];
                temp.y_error(temp.y_error >plotting.cutoff_error) = [];
                temp.x_error(isnan(temp.y_array)) = [];
                temp.y_error(isnan(temp.y_array)) = [];
                temp.x_array(isnan(temp.y_array)) = [];
                temp.y_array(isnan(temp.y_array)) = [];
                
                
%                 errorbar(temp.x_array, temp.y_array,temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
%                     'x--', 'color', color_setter, 'Linewidth', 3, 'DisplayName', ['State 2 lifetimes, flux = ' num2str(input_params.flux_1_value_list(m_flux)) '\Phi_0, ' ...
%                 'n_g = ' num2str(input_params.ng_1_value_list(m_gate))])     )
            elseif strcmp(plotting.poissonian_lifetime_repetitions_mode, 'histogrammed_together') 
                if strcmp(plotting.detunings_or_drive_freq, 'detunings')
                    temp.x_array = mean(squeeze(data.detunings(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e6;
                elseif strcmp(plotting.detunings_or_drive_freq, 'drive_freq')
                    temp.x_array = mean(squeeze(data.drive_freq_GHz(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e9;
                end
                temp.y_array = squeeze(post_run_analysis.Poissonian.lifetime_1(m_power, m_flux, m_gate, :, end));
                temp.y_error = squeeze(post_run_analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, :, end));
                last_non_zero_detuning = find(temp.x_array ~=0);
                last_non_zero_detuning = last_non_zero_detuning(end);
                temp.x_array(last_non_zero_detuning + 1:end) = [];
                temp.x_error(last_non_zero_detuning + 1:end) = [];
                temp.y_error(temp.y_array == 0) = [];
                temp.x_error(temp.y_array == 0) = [];
                temp.x_array(temp.y_array == 0) = [];
                temp.y_array(temp.y_array == 0) = [];
                %%% weed out lifetime fits with large errors
                temp.x_error(temp.y_error >plotting.cutoff_error) = [];
                temp.x_array(temp.y_error >plotting.cutoff_error) = [];
                temp.y_array(temp.y_error >plotting.cutoff_error) = [];
                temp.y_error(temp.y_error >plotting.cutoff_error) = [];
                temp.x_error(isnan(temp.y_array)) = [];
                temp.y_error(isnan(temp.y_array)) = [];
                temp.x_array(isnan(temp.y_array)) = [];
                temp.y_array(isnan(temp.y_array)) = [];
                

                errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                'x-', 'color', color_setter, 'Linewidth', 3, 'DisplayName', ['State 1, rep = ' num2str(m_repetition) ', flux = ' num2str(input_params.flux_1_value_list(m_flux)) '\Phi_0, ' ...
                'n_g = ' num2str(input_params.ng_1_value_list(m_gate))])     

                hold on
                if strcmp(plotting.detunings_or_drive_freq, 'detunings')
                    temp.x_array = mean(squeeze(data.detunings(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e6;
                elseif strcmp(plotting.detunings_or_drive_freq, 'drive_freq')
                    temp.x_array = mean(squeeze(data.drive_freq_GHz(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e9;
                end
                temp.y_array = squeeze(post_run_analysis.Poissonian.lifetime_2(m_power, m_flux, m_gate, :, end));
                temp.y_error = squeeze(post_run_analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, :, end));
                last_non_zero_detuning = find(temp.x_array ~=0);
                last_non_zero_detuning = last_non_zero_detuning(end);
                temp.x_array(last_non_zero_detuning + 1:end) = [];
                temp.x_error(last_non_zero_detuning + 1:end) = [];
                temp.y_error(temp.y_array == 0) = [];
                temp.x_error(temp.y_array == 0) = [];
                temp.x_array(temp.y_array == 0) = [];
                temp.y_array(temp.y_array == 0) = [];
                %%% weed out lifetime fits with large errors
                temp.x_error(temp.y_error >plotting.cutoff_error) = [];
                temp.x_array(temp.y_error >plotting.cutoff_error) = [];
                temp.y_array(temp.y_error >plotting.cutoff_error) = [];
                temp.y_error(temp.y_error >plotting.cutoff_error) = [];
                temp.x_error(isnan(temp.y_array)) = [];
                temp.y_error(isnan(temp.y_array)) = [];
                temp.x_array(isnan(temp.y_array)) = [];
                temp.y_array(isnan(temp.y_array)) = [];
                

%                 errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
%                 'x--', 'color', color_setter, 'Linewidth', 3, 'DisplayName', ['State 2, rep = ' num2str(m_repetition) ', flux = ' num2str(input_params.flux_1_value_list(m_flux)) '\Phi_0, ' ...
%                 'n_g = ' num2str(input_params.ng_1_value_list(m_gate))])     

                
            elseif (strcmp(plotting.poissonian_lifetime_repetitions_mode, 'separate_and_together') && user == 2)    
                if strcmp(plotting.detunings_or_drive_freq, 'detunings')
                    temp.x_array = mean(squeeze(data.detunings(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e6;
                elseif strcmp(plotting.detunings_or_drive_freq, 'drive_freq')
                    temp.x_array = mean(squeeze(data.drive_freq_GHz(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e9;
                end
                temp.y_array = squeeze(post_run_analysis.hist_together.Poissonian.poisson_lifetime_1_us(m_power, m_flux, m_gate, :, end));
                temp.y_error = squeeze(post_run_analysis.hist_together.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, :, end));
                last_non_zero_detuning = find(temp.x_array ~=0);
                last_non_zero_detuning = last_non_zero_detuning(end);
                temp.x_array(last_non_zero_detuning + 1:end) = [];
                temp.x_error(last_non_zero_detuning + 1:end) = [];
                temp.y_error(temp.y_array == 0) = [];
                temp.x_error(temp.y_array == 0) = [];
                temp.x_array(temp.y_array == 0) = [];
                temp.y_array(temp.y_array == 0) = [];
                %%% weed out lifetime fits with large errors
                temp.x_error(temp.y_error >plotting.cutoff_error) = [];
                temp.x_array(temp.y_error >plotting.cutoff_error) = [];
                temp.y_array(temp.y_error >plotting.cutoff_error) = [];
                temp.y_error(temp.y_error >plotting.cutoff_error) = [];
                temp.x_error(isnan(temp.y_array)) = [];
                temp.y_error(isnan(temp.y_array)) = [];
                temp.x_array(isnan(temp.y_array)) = [];
                temp.y_array(isnan(temp.y_array)) = [];
                length(temp.y_array)
                
                errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                'x-', 'color', color_setter, 'Linewidth', 3, 'DisplayName', ['State 1, flux = ' num2str(input_params.flux_1_value_list(m_flux)) '\Phi_0, ' ...
                'n_g = ' num2str(input_params.ng_1_value_list(m_gate))])     

                hold on
%                 if strcmp(plotting.detunings_or_drive_freq, 'detunings')
%                     temp.x_array = mean(squeeze(data.detunings(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
%                     temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e6;
%                 elseif strcmp(plotting.detunings_or_drive_freq, 'drive_freq')
%                     temp.x_array = mean(squeeze(data.drive_freq_GHz(m_power, m_flux, m_gate, :, :)), 2, 'omitnan');
%                     temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(input_params.detuning_array_number, 1)/1e9;
%                 end
%                 temp.y_array = squeeze(post_run_analysis.hist_together.Poissonian.poisson_lifetime_2_us(m_power, m_flux, m_gate, :, end));
%                 temp.y_error = squeeze(post_run_analysis.hist_together.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, :, end));
%                 last_non_zero_detuning = find(temp.x_array ~=0);
%                 last_non_zero_detuning = last_non_zero_detuning(end);
%                 temp.x_array(last_non_zero_detuning + 1:end) = [];
%                 temp.x_error(last_non_zero_detuning + 1:end) = [];
%                 temp.y_error(temp.y_array == 0) = [];
%                 temp.x_error(temp.y_array == 0) = [];
%                 temp.x_array(temp.y_array == 0) = [];
%                 temp.y_array(temp.y_array == 0) = [];
%                 %%% weed out lifetime fits with large errors
%                 temp.x_error(temp.y_error >plotting.cutoff_error) = [];
%                 temp.x_array(temp.y_error >plotting.cutoff_error) = [];
%                 temp.y_array(temp.y_error >plotting.cutoff_error) = [];
%                 temp.y_error(temp.y_error >plotting.cutoff_error) = [];
%                 errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
%                 'x--', 'color', color_setter, 'Linewidth', 3, 'DisplayName', ['State 2, flux = ' num2str(input_params.flux_1_value_list(m_flux)) '\Phi_0, ' ...
%                 'n_g = ' num2str(input_params.ng_1_value_list(m_gate))])     

            end
            number_plotting_points = number_plotting_points + length(temp.y_array);
            if strcmp(plotting.detunings_or_drive_freq, 'detunings')
                xlabel('$\Delta$ (MHz)', 'interpreter', 'latex')
                axis([-45 0 0 60])
            elseif strcmp(plotting.detunings_or_drive_freq, 'drive_freq')
                xlabel('$\omega_d$ (GHz)', 'interpreter', 'latex')
                axis([5.76 5.815 0 60])
            end
            ylabel('Time ($\mu$s)', 'interpreter', 'latex')
            title(['Lifetimes for fit for P$_{\mathrm{in}}$ = ' num2str(input_params.input_power_value_list(m_power)) 'dBm'], 'interpreter', 'latex')
            legend show

            if plotting.save_data_and_png_param == 1
                    save_file_name = [run_params.fig_directory num2str(m_power) '_' num2str(input_params.input_power_value_list(m_power)) 'dBm_lifetimes.png'];
                    saveas(Lifetime_detuning_plots, save_file_name)
                    save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_power) '_' num2str(input_params.input_power_value_list(m_power)) 'dBm_lifetimes.fig'];
                    saveas(Lifetime_detuning_plots, save_file_name)
                    close all
            end
            clear Lifetime_detuning_plots ...
                  save_file_name ...
                  last_non_zero_detuning ...
                  temp
        end
    end
    colorbar
    if strcmp(plotting.sort_by, 'gate')
        c = colorbar;
        hL = ylabel(c,'$n_g$(electrons)', 'interpreter', 'latex');     
        set(hL,'Rotation',90);
        c.Ticks = linspace(0, 1, length(plotting.gate_start_index:plotting.gate_step_index: ...
            plotting.gate_stop_index));
        c.TickLabels = round(input_params.ng_1_value_list(plotting.gate_start_index:plotting.gate_step_index: ...
            plotting.gate_stop_index), 2);
    elseif strcmp(plotting.sort_by, 'flux')
        c = colorbar;
        hL = ylabel(c,'$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex');     
        set(hL,'Rotation',90);
        c.Ticks = linspace(0, 1, length(plotting.gate_start_index:plotting.gate_step_index: ...
            plotting.gate_stop_index));
        c.TickLabels = round(input_params.ng_1_value_list(plotting.flux_start_index:plotting.flux_step_index: ...
            plotting.flux_stop_index), 2);
     elseif strcmp(plotting.sort_by, 'kerr')
         c = colorbar;
         hL = ylabel(c,'$K/2\pi$', 'interpreter', 'latex');     
         set(hL,'Rotation',90);
         c.Ticks = linspace(0, 1, 10);
         c.TickLabels = round(linspace(plotting.sorted_kerr_MHz(1), plotting.sorted_kerr_MHz(end), 10), 2);
    end
end
clear m_flux ...
      m_gate ...
      m_power ...
      m_repetition ...
      last_non_zero_detuning ... 
      plotting ...
      c