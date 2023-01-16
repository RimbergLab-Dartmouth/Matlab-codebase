%% plotting settings parameters
plotting.figs_visible = 1;
plotting.save_figures_png = 0;
plotting.save_figures_fig = 0;
plotting.save_analyzed_data = 0;
plotting.f_inverse_start_index = 3; 
plotting.f_inverse_stop_index = 3; % index from end to which stop fit
plotting.reanalyze = 0;
plotting.ej_ec_fit_reanalyze = 0;
plotting.q_circle_fits_reanalyze = 0;
plotting.noise_spectrum_reanalyze = 0;
%% plotting and saving location definitions
while plotting.reanalyze && (plotting.q_circle_fits_reanalyze || plotting.noise_spectrum_reanalyze) && ~exist('data', 'var')
    clearvars -except plotting
    disp('need data. select file')
    [file_name, file_path] = uigetfile;
    finput = file_name;
    load([file_path file_name] ,'-regexp', '^(?!(plotting)$).')   
    disp(['Loaded file : ' file_path file_name])
end

while plotting.figs_visible && ~plotting.reanalyze && ~exist('analysis', 'var')
    if exist('data', 'var')
        disp('need to analyze. change reanalyze parameter, or load file with analysis.')
        [file_name, file_path] = uigetfile;
        finput = file_name;
        load([file_path file_name] ,'-regexp', '^(?!(plotting)$).')   
        disp(['Loaded file : ' file_path file_name])
    else
        disp('need analysis. load file with analysis')
        [file_name, file_path] = uigetfile;
        finput = file_name;
        load([file_path file_name] ,'-regexp', '^(?!(plotting)$).')   
        disp(['Loaded file : ' file_path file_name])
    end    
end

if ~plotting.reanalyze && ~plotting.save_analyzed_data && ~plotting.figs_visible
    disp('What do you want this program to do? Sit here twiddling thumbs?')
    return
end

if ~isfield(input_params, 'file_name_time_stamp') && (plotting.save_figures_png || plotting.save_figures_fig || plotting.save_analyzed_data)
    disp('select directory where plots and data should be saved')
    plotting.save_folder = uigetdir;
elseif (plotting.save_figures_png || plotting.save_figures_fig || plotting.save_analyzed_data)
    plotting.save_folder = ['d' input_params.file_name_time_stamp '_q_circles/'];
end

if plotting.save_figures_png || plotting.save_figures_fig
    mkdir([cd plotting.save_folder '/plots'])
    if plotting.save_figures_png 
        plotting.png_file_dir = [cd '/' plotting.save_folder '/plots/'];
    end
    if plotting.save_figures_fig
        mkdir([cd plotting.save_folder '/plots/fig_files'])
        plotting.fig_file_dir = [cd '/' plotting.save_folder '/plots/fig_files/'];
    end
end
    
if plotting.save_analyzed_data
    plotting.mat_file_dir = [cd '/' plotting.save_folder];
end
%% guesses for Ej, Ec fit
if plotting.ej_ec_fit_reanalyze == 1 && plotting.reanalyze == 1
    guess.center_freq = 5.757e9;
    guess.Ej_guess = 14.8e9; % in  GHz
    guess.Ec_guess = 54.1e9; % in  GHz
    guess.number_charge_states = 9;
    guess.initial_params=[guess.center_freq,guess.Ej_guess,guess.Ec_guess];
    ej_ec_fit.options=optimset('MaxIter',100,'MaxFunEvals',1000,'TolFun',1e-10,'TolX',1e-10);
end
%% fit q cirlces
if plotting.reanalyze && plotting.q_circle_fits_reanalyze
    %%%% no freq flucs
    [analysis.no_flucs.resonance_fits,analysis.no_flucs.data_real,analysis.no_flucs.data_imag,analysis.no_flucs.theory_real, ...
        analysis.no_flucs.theory_imag,analysis.no_flucs.bias_values,analysis.no_flucs.err, analysis.no_flucs.resonance_fits_min] = ...
            resonance_fit_to_range_of_bias_data_with_freq_flucs_struct(data.vna, ...
            gain_prof, 0, 'no_flucs');
    %extract lin mag and phase in degs based on theory fits
    [temp.theory_lin_mag,temp.theory_phase_radians]=extract_lin_mag_phase_from_real_imag(analysis.no_flucs.theory_real,analysis.no_flucs.theory_imag);
    [analysis.no_flucs.theory_log_mag,analysis.no_flucs.theory_phase_degs]=extract_log_mag_phase_degs(temp.theory_lin_mag,temp.theory_phase_radians);
    
    %%%% with freq flucs    
    [analysis.flucs.resonance_fits,analysis.flucs.data_real,analysis.flucs.data_imag,analysis.flucs.theory_real, ...
        analysis.flucs.theory_imag,analysis.flucs.bias_values,analysis.flucs.err, analysis.flucs.resonance_fits_min] = ...
            resonance_fit_to_range_of_bias_data_with_freq_flucs_struct(data.vna, ...
            gain_prof, 0, 'flucs');
    %extract lin mag and phase in degs based on theory fits
    [temp.theory_lin_mag,temp.theory_phase_radians] = extract_lin_mag_phase_from_real_imag(analysis.flucs.theory_real,analysis.flucs.theory_imag);
    [analysis.flucs.theory_log_mag,analysis.flucs.theory_phase_degs] = extract_log_mag_phase_degs(temp.theory_lin_mag,temp.theory_phase_radians);
    
    %%%% with freq flucs and angle    
    [analysis.flucs_angle.resonance_fits,analysis.flucs_angle.data_real,analysis.flucs_angle.data_imag,analysis.flucs_angle.theory_real, ...
        analysis.flucs_angle.theory_imag,analysis.flucs_angle.bias_values,analysis.flucs_angle.err, analysis.flucs_angle.resonance_fits_min] = ...
            resonance_fit_to_range_of_bias_data_with_freq_flucs_struct(data.vna, ...
            gain_prof, 0, 'flucs_and_angle');
    %extract lin mag and phase in degs based on theory fits
    [temp.theory_lin_mag,temp.theory_phase_radians] = extract_lin_mag_phase_from_real_imag(analysis.flucs_angle.theory_real,analysis.flucs_angle.theory_imag);
    [analysis.flucs_angle.theory_log_mag,analysis.flucs_angle.theory_phase_degs] = extract_log_mag_phase_degs(temp.theory_lin_mag,temp.theory_phase_radians);
end
%% Fitting Ej and Ec to res freqs  
if plotting.ej_ec_fit_reanalyze == 1 && plotting.reanalyze == 1
    disp('fitting EJ and EC to the res freq data')
    if ~isfield(analysis, 'flucs_angle')
        disp('q-cirlces not available. load appropriate file or reanalyze')
        return
    end
    err = @(p) resonance_freqs_error_calc_struct(squeeze(analysis.flucs_angle.resonance_fits(:, :, 1)),input_params.flux_values,input_params.ng_values,p, guess.number_charge_states);
    [analysis.ej_ec_fit.params,analysis.ej_ec_fit.goodness_fit,analysis.ej_ec_fit.eflag,analysis.ej_ec_fit.output]=fminsearch(err,guess.initial_params,ej_ec_fit.options);
    clear err
    disp(['the goodness of the fit was ' num2str(analysis.ej_ec_fit.goodness_fit)])

    %%%% theory values for fitted ej and ec%%%%%%%%%%%
    [analysis.ej_ec_fit.theory_freqs, ~, ~, ~, analysis.ej_ec_fit.dE1fourth] = ...
        eigenvalues_v1_3_struct(analysis.ej_ec_fit.params(2), analysis.ej_ec_fit.params(3), guess.number_charge_states,input_params.flux_values,input_params.ng_values, ...
                                                                                0, analysis.ej_ec_fit.params(1), 6);
    analysis.ej_ec_fit.theory_freqs = analysis.ej_ec_fit.params(1) + analysis.ej_ec_fit.theory_freqs;
    analysis.ej_ec_fit.kerr = 1/2*analysis.ej_ec_fit.dE1fourth.*0.176^4;
    
    %%%%%%% theory values for Ben's Ej, Ec %%%%%%%%
    [analysis.ej_ec_ben_values.theory_freqs, ~, ~, ~, analysis.ej_ec_fit.dE1fourth] = ...
        eigenvalues_v1_3_struct(14.8e9, 54.1e9, guess.number_charge_states,input_params.flux_values,input_params.ng_values, ...
                                                                                0, guess.center_freq, 6);
    analysis.ej_ec_ben_values.theory_freqs = analysis.ej_ec_ben_values.theory_freqs + guess.center_freq;
    analysis.ej_ec_ben_values.kerr = 1/2*analysis.ej_ec_fit.dE1fourth.*0.176^4;
end
%%
if plotting.save_analyzed_data && plotting.reanalyze && (plotting.q_circle_fits_reanalyze || plotting.ej_ec_fit_reanalyze)
    save([plotting.mat_file_dir 'only_analysis.mat'],'-regexp', '^(?!(bias_point|data|gain_prof|plotting|guess)$).');
end
%% fit 1/f to SA noise data
if plotting.reanalyze && plotting.noise_spectrum_reanalyze
    analysis.sa.freq = data.sa.freq(:, :, :) - repmat(data.sa.freq(:, :, (input_params.sa.number_points - 1)/2 + 1), 1, 1, input_params.sa.number_points);
    analysis.sa.freq = analysis.sa.freq(:, :, (input_params.sa.number_points - 1)/2 + 1: end);
    analysis.sa.amp = (data.sa.amp(:, :, 1 : (input_params.sa.number_points - 1)/2 + 1) + data.sa.amp(:, :, (input_params.sa.number_points - 1)/2 + 1 : end))/2;
    analysis.sa.amp_carrier_off = (data.sa.amp_carrier_off(:, :, 1 : (input_params.sa.number_points - 1)/2 + 1) + data.sa.amp_carrier_off(:, :, (input_params.sa.number_points - 1)/2 + 1 : end))/2;
    analysis.sa.amp_difference = analysis.sa.amp - analysis.sa.amp_carrier_off;
    [~, analysis.sa.amp_watts] = convert_dBm_to_Vp(analysis.sa.amp_difference);
%     [~, analysis.sa.amp_carrier_off_watts] = convert_dBm_to_Vp(analysis.sa.amp_carrier_off);
    analysis.sa.psd_watts_Hz = analysis.sa.amp_difference / input_params.sa.RBW / input_params.sa.span * (input_params.sa.number_points - 1); 


    for m_flux = 1 : input_params.flux_number
        for m_ng = 1 : input_params.ng_number
            disp(['fitting noise spectrum flux = ' num2str(m_flux) ' of ' num2str(input_params.flux_number) ', gate = ' num2str(m_ng) ' of ' num2str(input_params.ng_number)])
            [analysis.spectrum.goodness_fit(m_flux, m_ng),analysis.spectrum.amp_fit(m_flux, m_ng),analysis.spectrum.exponent_fit(m_flux, m_ng), ...
                analysis.spectrum.theory_freqs(m_flux, m_ng, :), analysis.spectrum.theory_amp_watts(m_flux, m_ng, :)] = ...
                fit_f_inverse_law(squeeze(analysis.sa.freq(m_flux, m_ng, plotting.f_inverse_start_index:end - plotting.f_inverse_stop_index)),...
                squeeze(analysis.sa.psd_watts_Hz(m_flux, m_ng, plotting.f_inverse_start_index:end - plotting.f_inverse_stop_index)));
            %%%%% plot raw data for each point while fitting
%             figure
%             semilogx(squeeze(analysis.sa.freq(m_flux, m_ng, plotting.f_inverse_start_index:end - plotting.f_inverse_stop_index)),...
%                 squeeze(analysis.sa.psd_watts_Hz(m_flux, m_ng, plotting.f_inverse_start_index:end - plotting.f_inverse_stop_index)))
%             figure
%             semilogx(squeeze(analysis.sa.freq(m_flux, m_ng, plotting.f_inverse_start_index:end - plotting.f_inverse_stop_index)),...
%                 squeeze(analysis.sa.psd_watts_Hz(m_flux, m_ng, plotting.f_inverse_start_index:end - plotting.f_inverse_stop_index)), 'displayName', 'carrier on')
%             hold on
%             semilogx (squeeze(analysis.sa.freq(m_flux, m_ng, plotting.f_inverse_start_index:end - plotting.f_inverse_stop_index)), ...
%                 squeeze(analysis.sa.psd_watts_Hz_off(m_flux, m_ng, plotting.f_inverse_start_index:end - plotting.f_inverse_stop_index)), 'displayName', 'carrier off')
%             plot(squeeze(analysis.sa.freq(m_flux, m_ng, plotting.f_inverse_start_index:end - plotting.f_inverse_stop_index)), ...
%                 squeeze(analysis.spectrum.theory_amp_watts(m_flux, m_ng, :)), 'displayName', 'fit')
%             legend show
%             pause
%             close all
            %%%%%%%%%%%%
            [~, temp.index] = min(abs(gain_prof.freq - squeeze(analysis.flucs_angle.resonance_fits(m_flux, m_ng, 1))));
            analysis.system_effective_gain.closest_value (m_flux, m_ng) = gain_prof.amp(temp.index);  
            %%%% this is the value of the effective gain of the amp chain
            %%%% (input attenuation + amp gain => vna port to vna port),
            %%%% closest expected at the resonance freq
        end
    end
    analysis.spectrum.theory_amp = convert_watts_to_dBm(analysis.spectrum.theory_amp_watts);
    temp.freq_spacing = diff(data.sa.freq, 1, 3);
    analysis.sa.freq_spacing = mean(temp.freq_spacing(:));
    if std(temp.freq_spacing(:)) ~= 0
        disp('freq spacings are not uniform, but mean taken')
    end
    %%% see equation 36 of https://journals.aps.org/prapplied/pdf/10.1103/PhysRevApplied.15.044009
    %%% for this numerical factor
    [~, temp.input_power_watts] = convert_dBm_to_Vp(input_params.sig_gen.power);
    analysis.spectrum.numerical_factor = (analysis.flucs_angle.resonance_fits(:, :, 2) + analysis.flucs_angle.resonance_fits(:, :, 3)).^2 .* analysis.flucs_angle.resonance_fits(:, :, 1).^2 ...
        / 2 ./ analysis.flucs_angle.resonance_fits(:, :, 3).^2 / temp.input_power_watts ./ 10.^(analysis.system_effective_gain.closest_value/10);
    clear temp

    %%% total sigma from 1/f fit is (see eqn. 39 of paper above)
    analysis.spectrum.sigma = sqrt(squeeze(sum(analysis.spectrum.theory_amp_watts * analysis.sa.freq_spacing / input_params.sa.RBW, 3)) .* analysis.spectrum.numerical_factor); 

   %%%% save analysis data
    if plotting.save_analyzed_data     
        save([plotting.mat_file_dir '/only_analysis.mat'],'-regexp', '^(?!(bias_point|data|gain_prof|plotting|guess)$).');
    end
end


%% plotting section
%% Surface plotting res freqs
if plotting.figs_visible
    figure
    subplot(1, 3, 1)
    surf(input_params.ng_values, input_params.flux_values, squeeze(analysis.flucs_angle.resonance_fits(:, : , 1)/1e9), 'linestyle', 'none')
    xlabel('Gate electrons', 'interpreter', 'latex')    
    ylabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    title('data', 'interpreter', 'latex')
    caxis([5.71 5.815])
    view(0,90)
    subplot(1,3,2)
    surf(input_params.ng_values, input_params.flux_values, squeeze(analysis.ej_ec_fit.theory_freqs/1e9), 'linestyle', 'none')
%     legend (['average error = ' num2str(round(mean(mean(abs(analysis.ej_ec_fit.theory_freqs - squeeze(analysis.flucs_angle.resonance_fits(:, :, 1))))),2)/1e6) 'MHz'])
    title(['fit' 13 10 'average error = ' num2str(round(mean(mean(abs(analysis.ej_ec_fit.theory_freqs - squeeze(analysis.flucs_angle.resonance_fits(:, :, 1))))),2)/1e6) 'MHz'] ...
        , 'interpreter', 'latex')
    xlabel('Gate electrons', 'interpreter', 'latex')
    view(0,90)
    caxis([5.71 5.815])
    subplot(1,3,3)
    surf(input_params.ng_values, input_params.flux_values, squeeze(analysis.ej_ec_ben_values.theory_freqs/1e9), 'linestyle', 'none')
    title(['Ben fit' 13 10 'average error = ' num2str(round(mean(mean(abs(analysis.ej_ec_ben_values.theory_freqs - squeeze(analysis.flucs_angle.resonance_fits(:, :, 1))))),2)/1e6) 'MHz'], ...
        'interpreter', 'latex')
    xlabel('Gate electrons', 'interpreter', 'latex')
    view(0,90)
    caxis([5.71 5.815])    
    c = colorbar;
    hL = ylabel(c,'$\omega_0/2\pi$(GHz)', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL
    sgtitle(['Fit values : $E_J$ = ' num2str(round(analysis.ej_ec_fit.params(2)/1e9, 2)) ' GHz, $E_C$ = ' num2str(round(analysis.ej_ec_fit.params(3)/1e9, 2)) ' GHz' 13 10 ...
        'Ben fit : $E_J$ = 14.8 GHz, $E_C$ = 52.1 GHz' ], 'interpreter', 'latex', 'fontsize', 46)
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'res_freqs_surf_plots.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'res_freqs_surf_plots.fig'])
    end    
end
%% Surface Plotting res freqs fit errors
if plotting.figs_visible
    figure
    subplot(1, 2, 1)
    surf(input_params.ng_values, input_params.flux_values, abs(squeeze(analysis.ej_ec_fit.theory_freqs - analysis.flucs_angle.resonance_fits(:, : , 1))/1e6), 'linestyle', 'none')
    xlabel('Gate electrons', 'interpreter', 'latex')
    ylabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    title(['Res freq error' 13 10 ' mean = ' num2str(round(mean(mean(abs(squeeze(analysis.ej_ec_fit.theory_freqs - analysis.flucs_angle.resonance_fits(:, : , 1))/1e6))),2)) 'MHz'], 'interpreter', 'latex')
    caxis([.1 4])
    view(0,90)
    subplot(1,2,2)
    surf(input_params.ng_values, input_params.flux_values, squeeze((abs(analysis.ej_ec_ben_values.theory_freqs - analysis.flucs_angle.resonance_fits(:, : , 1)))/1e6), 'linestyle', 'none')
%     legend (['average error = ' num2str(round(mean(mean(abs(analysis.ej_ec_fit.theory_freqs - squeeze(analysis.flucs_angle.resonance_fits(:, :, 1))))),2)/1e6) 'MHz'])
    title(['Ben res freq error' 13 10 'mean = ' num2str(round(mean(mean(abs(squeeze(analysis.ej_ec_ben_values.theory_freqs - analysis.flucs_angle.resonance_fits(:, : , 1))/1e6))),2)) 'MHz'], 'interpreter', 'latex')
    xlabel('Gate electrons', 'interpreter', 'latex')
    view(0,90)
    caxis([1 4])    
    c = colorbar;
    hL = ylabel(c,'$\Delta\omega_0/2\pi$(MHz)', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL
    sgtitle(['Fit values : $E_J$ = ' num2str(round(analysis.ej_ec_fit.params(2)/1e9, 2)) ' GHz, $E_C$ = ' num2str(round(analysis.ej_ec_fit.params(3)/1e9, 2)) ' GHz' 13 10 ...
        'Ben fit : $E_J$ = 14.8 GHz, $E_C$ = 52.1 GHz' ], 'interpreter', 'latex', 'fontsize', 46)
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'res_freqs_fit_to_data_error_surf_plots.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'res_freqs_fit_to_data_error_surf_plots.fig'])
    end    
end
%% Surface Plotting q-circle fit error 
if plotting.figs_visible
    figure
    surf(input_params.ng_values, input_params.flux_values, analysis.flucs_angle.err, 'linestyle', 'none')
    xlabel('Gate electrons', 'interpreter', 'latex')    
    ylabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    title('q-circle fit error', 'interpreter', 'latex')
    caxis([min(min(analysis.flucs_angle.err)) max(max(analysis.flucs_angle.err))])
    view(0,90)
    c = colorbar;
    hL = ylabel(c,'Fit error (arb. units)', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'q_circle_fit_error_surf_plots.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'q_circle_fit_error_surf_plots.fig'])
    end   
end
%% Surface Plotting damping rates 
if plotting.figs_visible
    figure
    subplot(1, 2, 1)
    surf(input_params.ng_values, input_params.flux_values, squeeze(analysis.flucs_angle.resonance_fits(:, : , 2)/1e6), 'linestyle', 'none')
    xlabel('Gate electrons', 'interpreter', 'latex')    
    ylabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    title('$\kappa_{\mathrm{int}}/2\pi$', 'interpreter', 'latex')
    caxis([.1 1.5])
    view(0,90)
    subplot(1,2,2)
    surf(input_params.ng_values, input_params.flux_values, squeeze(analysis.flucs_angle.resonance_fits(:, : , 3)/1e6), 'linestyle', 'none')
%     legend (['average error = ' num2str(round(mean(mean(abs(analysis.ej_ec_fit.theory_freqs - squeeze(analysis.flucs_angle.resonance_fits(:, :, 1))))),2)/1e6) 'MHz'])
    title('fit')
    xlabel('Gate electrons', 'interpreter', 'latex')
    title('$\kappa_{\mathrm{ext}}/2\pi$', 'interpreter', 'latex')
    view(0,90)
    caxis([.1 1.5])
    c = colorbar;
    hL = ylabel(c,'$\kappa_{\mathrm{int/ext}}/2\pi$(MHz)', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL
    sgtitle('Damping rates', 'interpreter', 'latex', 'fontsize', 46)
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'damping_rates_surf_plots.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'damping_rates_surf_plots.fig'])
    end      
end
%% Surface Plotting fitting angle 
if plotting.figs_visible
    figure
    surf(input_params.ng_values, input_params.flux_values, squeeze(analysis.flucs_angle.resonance_fits(:, : , 5)), 'linestyle', 'none')
    xlabel('Gate electrons', 'interpreter', 'latex')    
    ylabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    title('Angle of q-circle rotation ($^\circ$)', 'interpreter', 'latex')
    caxis([-10 10])
    c = colorbar;
    hL = ylabel(c,'Angle ($^\circ$)', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL
    view(0,90)
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'fit_angle_surf_plots.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'fit_angle_surf_plots.fig'])
    end     
end
%% Surface Plotting sigma freq flucs VNA surf plot
if plotting.figs_visible
    figure
    surf(input_params.ng_values, input_params.flux_values, squeeze(analysis.flucs_angle.resonance_fits(:, : , 4)/1e6), 'linestyle', 'none')
    xlabel('Gate electrons', 'interpreter', 'latex')    
    ylabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    title('Freq fluctuations $\sigma_{\omega_0}/2\pi$(MHz)', 'interpreter', 'latex')
    caxis([.3 1.7])
    c = colorbar;
    hL = ylabel(c,'$\sigma_{\omega_0}/2\pi$(MHz)', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL
    view(0,90)
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'freq_flucs_surf_plots.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'freq_flucs_surf_plots.fig'])
    end     
end
%% Surface Plotting simulated Kerr 
if plotting.figs_visible
    figure
    subplot(1, 2, 1)
    surf(input_params.ng_values, input_params.flux_values, analysis.ej_ec_fit.kerr/1e6, 'linestyle', 'none')
    xlabel('Gate electrons', 'interpreter', 'latex')    
    ylabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    title('Fit', 'interpreter', 'latex')
    colormap(redblue)
    caxis([-1 1])
    view(0,90)
    subplot(1,2,2)
    surf(input_params.ng_values, input_params.flux_values, analysis.ej_ec_ben_values.kerr/1e6, 'linestyle', 'none')
    title('Ben fit', 'interpreter', 'latex')
    colormap(redblue)
    xlabel('Gate electrons', 'interpreter', 'latex')
    view(0,90)
    caxis([-1 1])
    c = colorbar;
    hL = ylabel(c,'$K/2\pi$(MHz)', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL
    sgtitle('$K/2\pi$', 'interpreter', 'latex', 'fontsize', 46)
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'kerr_surf_plots.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'kerr_surf_plots.fig'])
    end     
end
%% Gate Plotting res freqs vs gates, different fluxes are different colours
if plotting.figs_visible
    y_axis_start_value = 5.7;
    y_axis_end_value = 5.815;
    colors = parula(input_params.flux_number);
    figure
    hold on
    for m_flux = 1:input_params.flux_number
        plot(input_params.ng_values,squeeze(analysis.flucs_angle.resonance_fits(m_flux, :, 1))/1e9, '-x', ...
        'markersize', 16, 'color', colors(m_flux, :))
    end
    xlabel('Gate electrons', 'interpreter', 'latex')
    ylabel('$\omega_0/2\pi$(GHz)', 'interpreter', 'latex')
    title('Resonance freqs from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.ng_values(1) input_params.ng_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    hL = ylabel(c,'$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.flux_values(1), input_params.flux_values(end), 10), 2);
    clear c ...
          hL ...
          m_flux ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'res_freq_line_plots_vs_gate.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'res_freq_line_plots_vs_gate.fig'])
    end       
end
%% Gate Plotting internal damping rates vs gates, different fluxes are different colours
if plotting.figs_visible
    y_axis_start_value = 0.1;
    y_axis_end_value = 3;
    colors = parula(input_params.flux_number);
    figure
    hold on
    for m_flux = 1 : input_params.flux_number
        plot(input_params.ng_values,squeeze(analysis.flucs_angle.resonance_fits(m_flux, :, 2))/1e6, '-x', ...
        'markersize', 16, 'color', colors(m_flux, :))
    end
    xlabel('Gate electrons', 'interpreter', 'latex')
    ylabel('$\kappa_{\mathrm{int}}/2\pi$(MHz)', 'interpreter', 'latex')
    title('Internal damping rate from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.ng_values(1) input_params.ng_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    hL = ylabel(c,'$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex');     
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.flux_values(1), input_params.flux_values(end), 10), 2);
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_flux ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'kappa_int_line_plots_vs_gate.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'kappa_int_line_plots_vs_gate.fig'])
    end       
end
%% Gate Plotting external damping rates vs gates, different fluxes are different colours
if plotting.figs_visible
    y_axis_start_value = 0.7;
    y_axis_end_value = 1.4;
    colors = parula(input_params.flux_number);
    figure
    hold on
    for m_flux = 1 : input_params.flux_number
        plot(input_params.ng_values,squeeze(analysis.flucs_angle.resonance_fits(m_flux, :, 3))/1e6, '-x', ...
        'markersize', 16, 'color', colors(m_flux, :))
    end
    xlabel('Gate electrons', 'interpreter', 'latex')
    ylabel('$\kappa_{\mathrm{ext}}/2\pi$(MHz)', 'interpreter', 'latex')
    title('External damping rate from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.ng_values(1) input_params.ng_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    hL = ylabel(c,'$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex');  
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.flux_values(1), input_params.flux_values(end), 10), 2);   
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_flux ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'kappa_ext_line_plots_vs_gate.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'kappa_ext_line_plots_vs_gate.fig'])
    end       
end
%% Gate Plotting freq flucs vs gates, different fluxes are different colours
if plotting.figs_visible
    y_axis_start_value = 0.1;
    y_axis_end_value = 3;
    colors = parula(input_params.flux_number);
    figure
    hold on
    for m_flux = 1 : input_params.flux_number
        plot(input_params.ng_values,squeeze(analysis.flucs_angle.resonance_fits(m_flux, :, 4))/1e6, '-x', ...
        'markersize', 16, 'color', colors(m_flux, :))
    end
    xlabel('Gate electrons', 'interpreter', 'latex')
    ylabel('$\sigma_{\omega_0}/2\pi$(MHz)', 'interpreter', 'latex')
    title('Frequency fluctuations from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.ng_values(1) input_params.ng_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.flux_values(1), input_params.flux_values(end), 10), 2);
    hL = ylabel(c,'$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_flux ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'freq_flucs_line_plots_vs_gate.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'freq_flucs_line_plots_vs_gate.fig'])
    end       
end
%% Gate Plotting simulated Kerr vs gates, different fluxes are different colours
if plotting.figs_visible
    y_axis_start_value = -800;
    y_axis_end_value = 800;
    colors = parula(input_params.flux_number);
    figure
    hold on
    for m_flux = 1 : input_params.flux_number
        plot(input_params.ng_values,squeeze(analysis.ej_ec_fit.kerr(m_flux, :))/1e3, '-x', ...
        'markersize', 16, 'color', colors(m_flux, :))
    end
    xlabel('Gate electrons', 'interpreter', 'latex')
    ylabel('$K/2\pi$(kHz)', 'interpreter', 'latex')
    title('Kerr simulated from fit with flucs and angle values', 'interpreter', 'latex')
    axis([input_params.ng_values(1) input_params.ng_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.flux_values(1), input_params.flux_values(end), 10), 2);
    hL = ylabel(c,'$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_flux ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'Kerr_simulated_line_plots_vs_gate.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'Kerr_simulated_line_plots_vs_gate.fig'])
    end       
end
%% Gate Plotting impedance mismatch angle vs gates, different fluxes are different colours
if plotting.figs_visible
    y_axis_start_value = -10;
    y_axis_end_value = 10;
    colors = parula(input_params.flux_number);
    figure
    hold on
    for m_flux = 1 : input_params.flux_number
        plot(input_params.ng_values,squeeze(analysis.flucs_angle.resonance_fits(m_flux, :, 5)), '-x', ...
        'markersize', 16, 'color', colors(m_flux, :))
    end
    xlabel('Gate electrons', 'interpreter', 'latex')
    ylabel('Angle($^\circ$)', 'interpreter', 'latex')
    title('Impedance mismatch angle from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.ng_values(1) input_params.ng_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.flux_values(1), input_params.flux_values(end), 10), 2);
    hL = ylabel(c,'$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_flux ...
          colors
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'impedance_mismatch_angle_line_plots_vs_gate.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'impedance_mismatch_angle_line_plots_vs_gate.fig'])
    end       
end
%% Gate Plotting q-circle fit error vs gates, different fluxes are different colours
if plotting.figs_visible
    y_axis_start_value = -10;
    y_axis_end_value = 10;
    colors = parula(input_params.flux_number);
    figure
    hold on
    for m_flux = 1 : input_params.flux_number
        plot(input_params.ng_values,squeeze(analysis.flucs_angle.err(m_flux, :)), '-x', ...
        'markersize', 16, 'color', colors(m_flux, :))
    end
    xlabel('Gate electrons', 'interpreter', 'latex')
    ylabel('Fit error (arb. units)', 'interpreter', 'latex')
    title('Q circle fit errors from fit with flucs and angle', 'interpreter', 'latex')
%     axis([input_params.ng_values(1) input_params.ng_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.flux_values(1), input_params.flux_values(end), 10), 2);
    hL = ylabel(c,'$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_flux ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'q_circle_fit_error_line_plots_vs_gate.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'q_circle_fit_error_line_plots_vs_gate.fig'])
    end       
end
%% Flux Plotting res freqs vs flux, different gates are different colours
if plotting.figs_visible
    y_axis_start_value = 5.7;
    y_axis_end_value = 5.815;
    colors = parula(input_params.ng_number);
    figure
    hold on
    for m_gate = 1 : input_params.ng_number
        plot(input_params.flux_values,squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 1))/1e9, '-x', ...
        'markersize', 16, 'color', colors(m_gate, :))
    end
    xlabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    ylabel('$\omega_0/2\pi$(GHz)', 'interpreter', 'latex')
    title('Resonance freqs from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.flux_values(1) input_params.flux_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    hL = ylabel(c,'gate electrons', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.ng_values(1), input_params.ng_values(end), 10), 2);
    clear c ...
          hL ...
          m_gate ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'res_freq_line_plots_vs_flux.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'res_freq_line_plots_vs_flux.fig'])
    end       
end
%% Flux Plotting internal damping rates vs flux, different gate are different colours
if plotting.figs_visible
    y_axis_start_value = 0.1;
    y_axis_end_value = 3;
    colors = parula(input_params.ng_number);
    figure
    hold on
    for m_gate = 1 : input_params.flux_number
        plot(input_params.flux_values,squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 2))/1e6, '-x', ...
        'markersize', 16, 'color', colors(m_gate, :))
    end
    xlabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    ylabel('$\kappa_{\mathrm{int}}/2\pi$(MHz)', 'interpreter', 'latex')
    title('Internal damping rate from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.flux_values(1) input_params.flux_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    hL = ylabel(c,'gate electrons', 'interpreter', 'latex');     
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.ng_values(1), input_params.ng_values(end), 10), 2);
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_gate ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'kappa_int_line_plots_vs_flux.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'kappa_int_line_plots_vs_flux.fig'])
    end       
end
%% Flux Plotting external damping rates vs flux, different gates are different colours
if plotting.figs_visible
    y_axis_start_value = 0.7;
    y_axis_end_value = 1.4;
    colors = parula(input_params.ng_number);
    figure
    hold on
    for m_gate = 1 : input_params.flux_number
        plot(input_params.flux_values,squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 3))/1e6, '-x', ...
        'markersize', 16, 'color', colors(m_gate, :))
    end
    xlabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    ylabel('$\kappa_{\mathrm{ext}}/2\pi$(MHz)', 'interpreter', 'latex')
    title('External damping rate from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.flux_values(1) input_params.flux_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    hL = ylabel(c,'gate electrons', 'interpreter', 'latex');  
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.ng_values(1), input_params.ng_values(end), 10), 2);   
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_gate ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'kappa_ext_line_plots_vs_flux.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'kappa_ext_line_plots_vs_flux.fig'])
    end       
end
%% Flux Plotting freq flucs vs flux, different gates are different colours
if plotting.figs_visible
    y_axis_start_value = 0.1;
    y_axis_end_value = 3;
    colors = parula(input_params.ng_number);
    figure
    hold on
    for m_gate = 1 : input_params.flux_number
        plot(input_params.flux_values,squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 4))/1e6, '-x', ...
        'markersize', 16, 'color', colors(m_gate, :))
    end
    xlabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    ylabel('$\sigma_{\omega_0}/2\pi$(MHz)', 'interpreter', 'latex')
    title('Frequency fluctuations from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.flux_values(1) input_params.flux_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.ng_values(1), input_params.ng_values(end), 10), 2);
    hL = ylabel(c,'gate electrons', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_gate ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'freq_flucs_line_plots_vs_flux.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'freq_flucs_line_plots_vs_flux.fig'])
    end       
end
%% Flux Plotting simulated Kerr vs flux, different gates are different colours
if plotting.figs_visible
    y_axis_start_value = -800;
    y_axis_end_value = 800;
    colors = parula(input_params.ng_number);
    figure
    hold on
    for m_gate = 1 : input_params.flux_number
        plot(input_params.flux_values,squeeze(analysis.ej_ec_fit.kerr(:, m_gate))/1e3, '-x', ...
        'markersize', 16, 'color', colors(m_gate, :))
    end
    xlabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    ylabel('$K/2\pi$(kHz)', 'interpreter', 'latex')
    title('Kerr simulated from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.flux_values(1) input_params.flux_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.ng_values(1), input_params.ng_values(end), 10), 2);
    hL = ylabel(c,'gate electrons', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_gate ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'Kerr_line_plots_vs_flux.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'Kerr_line_plots_vs_flux.fig'])
    end       
end
%% FluxPlotting impedance mismatch angle vs flux, different gates are different colours
if plotting.figs_visible
    y_axis_start_value = -10;
    y_axis_end_value = 10;
    colors = parula(input_params.ng_number);
    figure
    hold on
    for m_gate = 1 : input_params.flux_number
        plot(input_params.flux_values,squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 5)), '-x', ...
        'markersize', 16, 'color', colors(m_gate, :))
    end
    xlabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    ylabel('Angle($^\circ$)', 'interpreter', 'latex')
    title('Impedance mismatch angle from fit with flucs and angle', 'interpreter', 'latex')
    axis([input_params.flux_values(1) input_params.flux_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.ng_values(1), input_params.ng_values(end), 10), 2);
    hL = ylabel(c,'gate electrons', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_gate ...
          colors
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'impedance_mismatch_angle_line_plots_vs_flux.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'impedance_mismatch_angle_line_plots_vs_flux.fig'])
    end       
end
%% Flux Plotting q-circle fit error vs flux, different gates are different colours
if plotting.figs_visible
    y_axis_start_value = -10;
    y_axis_end_value = 10;
    colors = parula(input_params.ng_number);
    figure
    hold on
    for m_gate = 1 : input_params.flux_number
        plot(input_params.flux_values,squeeze(analysis.flucs_angle.err(:, m_gate)), '-x', ...
        'markersize', 16, 'color', colors(m_gate, :))
    end
    xlabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    ylabel('Fit error (arb. units)', 'interpreter', 'latex')
    title('Q circle fit errors from fit with flucs and angle', 'interpreter', 'latex')
%     axis([input_params.flux_values(1) input_params.flux_values(end) y_axis_start_value y_axis_end_value])
    c = colorbar;
    c.Ticks = linspace(0, 1, 10);
    c.TickLabels = round(linspace(input_params.ng_values(1), input_params.ng_values(end), 10), 2);
    hL = ylabel(c,'gate electrons', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL ...
          m_gate ...
          colors ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'q_circle_fit_error_line_plots_vs_flux.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'q_circle_fit_error_line_plots_vs_flux.fig'])
    end       
end
%% Res Freq Plotting internal damping rates vs resonance frequency
if plotting.figs_visible
    x_axis_start_value = 5.7;
    x_axis_end_value = 5.815;
    y_axis_start_value = 0.1;
    y_axis_end_value = 1;
    figure
    hold on
    for m_gate = 1 : input_params.flux_number
        plot(squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 1))/1e9,squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 2))/1e6, '-bx', ...
        'markersize', 16)
    end
    xlabel('$\omega_0$ (GHz)', 'interpreter', 'latex')
    ylabel('$\kappa_{\mathrm{int}}$ (MHz)', 'interpreter', 'latex')
    title(['Internal damping rates vs resonance frequency' 13 10 ...
        'Fit values : $E_J$ = ' num2str(round(analysis.ej_ec_fit.params(2)/1e9, 2)) ' GHz, $E_C$ = ' ...
        num2str(round(analysis.ej_ec_fit.params(3)/1e9, 2)) ' GHz'], 'interpreter', 'latex')
    axis([x_axis_start_value x_axis_end_value y_axis_start_value y_axis_end_value])
    clear m_gate ...
          x_axis_start_value ...
          x_axis_end_value ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'internal_damping_rate_vs_res_freq.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'internal_damping_rate_vs_res_freq.fig'])
    end       
end
%% Res Freq Plotting external damping rates vs resonance frequency
if plotting.figs_visible
    x_axis_start_value = 5.7;
    x_axis_end_value = 5.815;
    y_axis_start_value = 0.7;
    y_axis_end_value = 1.5;
    figure
    hold on
    for m_gate = 1 : input_params.flux_number
        plot(squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 1))/1e9,squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 3))/1e6, '-bx', ...
        'markersize', 16)
    end
    xlabel('$\omega_0$ (GHz)', 'interpreter', 'latex')
    ylabel('$\kappa_{\mathrm{ext}}$ (MHz)', 'interpreter', 'latex')
    title(['External damping rates vs resonance frequency' 13 10 ...
        'Fit values : $E_J$ = ' num2str(round(analysis.ej_ec_fit.params(2)/1e9, 2)) ' GHz, $E_C$ = ' ...
        num2str(round(analysis.ej_ec_fit.params(3)/1e9, 2)) ' GHz'], 'interpreter', 'latex')
    axis([x_axis_start_value x_axis_end_value y_axis_start_value y_axis_end_value])
    clear m_gate ...
          x_axis_start_value ...
          x_axis_end_value ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'external_damping_rate_vs_res_freq.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'external_damping_rate_vs_res_freq.fig'])
    end       
end
%% Res Freq Plotting sigma vs resonance frequency
if plotting.figs_visible
    x_axis_start_value = 5.7;
    x_axis_end_value = 5.815;
    y_axis_start_value = 0.1;
    y_axis_end_value = 2;
    figure
    hold on
    for m_gate = 1 : input_params.flux_number
        plot(squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 1))/1e9,squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 4))/1e6, '-bx', ...
        'markersize', 16)
    end
    xlabel('$\omega_0$ (GHz)', 'interpreter', 'latex')
    ylabel('$\sigma_{\omega_0}$ (MHz)', 'interpreter', 'latex')
    title(['Frequency fluctuations vs resonance frequency' 13 10 ...
        'Fit values : $E_J$ = ' num2str(round(analysis.ej_ec_fit.params(2)/1e9, 2)) ' GHz, $E_C$ = ' ...
        num2str(round(analysis.ej_ec_fit.params(3)/1e9, 2)) ' GHz'], 'interpreter', 'latex')
    axis([x_axis_start_value x_axis_end_value y_axis_start_value y_axis_end_value])
    clear m_gate ...
          x_axis_start_value ...
          x_axis_end_value ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'freq_flucs_vs_res_freq.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'freq_flucs_vs_res_freq.fig'])
    end       
end
%% Res Freq Plotting impedance mismatch angle vs resonance frequency
if plotting.figs_visible
    x_axis_start_value = 5.7;
    x_axis_end_value = 5.815;
    y_axis_start_value = 0.1;
    y_axis_end_value = 2;
    figure
    hold on
    for m_gate = 1 : input_params.flux_number
        plot(squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 1))/1e9,squeeze(analysis.flucs_angle.resonance_fits(:, m_gate, 5)), '-bx', ...
        'markersize', 16)
    end
    xlabel('$\omega_0$ (GHz)', 'interpreter', 'latex')
    ylabel('Angle ($^\circ$)', 'interpreter', 'latex')
    title(['Impedance mismatch angle vs resonance frequency' 13 10 ...
        'Fit values : $E_J$ = ' num2str(round(analysis.ej_ec_fit.params(2)/1e9, 2)) ' GHz, $E_C$ = ' ...
        num2str(round(analysis.ej_ec_fit.params(3)/1e9, 2)) ' GHz'], 'interpreter', 'latex')
    axis([x_axis_start_value x_axis_end_value y_axis_start_value y_axis_end_value])
    clear m_gate ...
          x_axis_start_value ...
          x_axis_end_value ...
          y_axis_start_value ...
          y_axis_end_value
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'impedance_mismatch_angle_vs_res_freq.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'impedance_mismatch_angle_vs_res_freq.fig'])
    end       
end


%% Surface Plotting sigma freq flucs noise spectrum 
if plotting.figs_visible
    figure
    surf(input_params.ng_values, input_params.flux_values, analysis.spectrum.sigma, 'linestyle', 'none')
    xlabel('Gate electrons', 'interpreter', 'latex')    
    ylabel('$\Phi_{\mathrm{ext}}/\Phi_0$', 'interpreter', 'latex')
    title('Freq fluctuations from spectrum $\sigma_{\omega_0}/2\pi$(MHz)', 'interpreter', 'latex')
    caxis([.3 1.7])
    c = colorbar;
    hL = ylabel(c,'$\sigma_{\omega_0}/2\pi$(MHz)', 'interpreter', 'latex');     
    set(hL,'Rotation',90);
    clear c ...
          hL
    view(0,90)
    if plotting.save_figures_png
        saveas(gcf, [plotting.png_file_dir 'noise_spectrum_surf_plots.png'])
    end
    if plotting.save_figures_fig
        saveas(gcf, [plotting.fig_file_dir 'noise_spectrum_surf_plots.fig'])
    end     
end