%% plotting settings parameters
plotting.visible_
plotting.save_figures_png = 0;
plotting.save_figures_fig = 0;
plotting.save_analyzed_data = 0;
plotting.f_inverse_start_index = 3; 
plotting.reanalyze = 0;
%% plotting and saving location definitions
if ~exist('data', 'var')
    clearvars -except plotting
    [file_name, file_path] = uigetfile;
    finput = file_name;
    load([file_path file_name] ,'-regexp', '^(?!(plotting)$).')   
    disp(['Loaded file : ' file_path file_name])
end

if ~exist('analysis', 'var')
    disp('need analyzed data. If refitting required change parameter and retry.')
end
if ~isfield(input_params, 'file_name_time_stamp') && (plotting.save_figures_png || plotting.save_figures_fig || plotting.save_analyzed_data)
    disp('select directory where plots and data should be saved')
    plotting.save_folder = uigetdir;
elseif (plotting.save_figures_png || plotting.save_figures_fig || plotting.save_analyzed_data)
    plotting.save_folder = ['d' input_params.file_name_time_stamp '_q_cirlces/'];
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

%% fit q cirlces
if plotting.reanalyze
    %%%% no freq flucs
    [analysis.no_flucs.resonance_fits,analysis.no_flucs.data_real,analysis.no_flucs.data_imag,analysis.no_flucs.theory_real, ...
        analysis.no_flucs.theory_imag,analysis.no_flucs.bias_values,analysis.no_flucs.err, analysis.no_flucs.resonance_fits_min] = ...
            resonance_fit_to_range_of_bias_data_with_freq_flucs_struct(data.vna, ...
            gain_prof, 'no_flucs', 0);
    %extract lin mag and phase in degs based on theory fits
    [temp.theory_lin_mag,temp.theory_phase_radians]=extract_lin_mag_phase_from_real_imag(analysis.no_flucs.theory_real,analysis.no_flucs.theory_imag);
    [analysis.no_flucs.theory_log_mag,analysis.no_flucs.theory_phase_degs]=extract_log_mag_phase_degs(temp.theory_lin_mag,temp.theory_phase_radians);
    
    %%%% with freq flucs    
    [analysis.flucs.resonance_fits,analysis.flucs.data_real,analysis.flucs.data_imag,analysis.flucs.theory_real, ...
        analysis.flucs.theory_imag,analysis.flucs.bias_values,analysis.flucs.err, analysis.flucs.resonance_fits_min] = ...
            resonance_fit_to_range_of_bias_data_with_freq_flucs_struct(data.vna, ...
            gain_prof, 'flucs', 0);
    %extract lin mag and phase in degs based on theory fits
    [temp.theory_lin_mag,temp.theory_phase_radians] = extract_lin_mag_phase_from_real_imag(analysis.flucs.theory_real,analysis.flucs.theory_imag);
    [analysis.flucs.theory_log_mag,analysis.flucs.theory_phase_degs] = extract_log_mag_phase_degs(temp.theory_lin_mag,temp.theory_phase_radians);
    
    %%%% with freq flucs and angle    
    [analysis.flucs_angle.resonance_fits,analysis.flucs_angle.data_real,analysis.flucs_angle.data_imag,analysis.flucs_angle.theory_real, ...
        analysis.flucs_angle.theory_imag,analysis.flucs_angle.bias_values,analysis.flucs_angle.err, analysis.flucs_angle.resonance_fits_min] = ...
            resonance_fit_to_range_of_bias_data_with_freq_flucs_struct(data.vna, ...
            gain_prof, 'flucs_and_angle', 0);
    %extract lin mag and phase in degs based on theory fits
    [temp.theory_lin_mag,temp.theory_phase_radians] = extract_lin_mag_phase_from_real_imag(analysis.flucs_angle.theory_real,analysis.flucs_angle.theory_imag);
    [analysis.flucs_angle.theory_log_mag,analysis.flucs_angle.theory_phase_degs] = extract_log_mag_phase_degs(temp.theory_lin_mag,temp.theory_phase_radians);
    
end        
if plotting.save_analyzed_data     
    save([plotting.mat_file_dir 'only_analysis.mat'],'-regexp', '^(?!(bias_point|data|gain_prof)$).');
end
%% fit 1/f to SA noise data
if plotting.reanalyze
    analysis.sa.freq = data.sa.freq(:, :, :) - repmat(data.sa.freq(:, :, (input_params.sa.number_points - 1)/2 + 1), 1, 1, input_params.sa.number_points);
    analysis.sa.freq = analysis.sa.freq(:, :, (input_params.sa.number_points - 1)/2 + 1: end);
    analysis.sa.amp = (data.sa.amp(:, :, 1 : (input_params.sa.number_points - 1)/2 + 1) + data.sa.amp(:, :, (input_params.sa.number_points - 1)/2 + 1 : end))/2;
    analysis.sa.amp_carrier_off = (data.sa.amp_carrier_off(:, :, 1 : (input_params.sa.number_points - 1)/2 + 1) + data.sa.amp_carrier_off(:, :, (input_params.sa.number_points - 1)/2 + 1 : end))/2;
    [~, analysis.sa.amp_watts] = convert_dBm_to_Vp(analysis.sa.amp);
    [~, analysis.sa.amp_carrier_off_watts] = convert_dBm_to_Vp(analysis.sa.amp_carrier_off);

    for m_flux = 1 : input_params.flux_number
        for m_ng = 1 : input_params.ng_number
            [analysis.spectrum.goodness_fit(m_flux, m_ng),analysis.spectrum.amp_fit(m_flux, m_ng),analysis.spectrum.exponent_fit(m_flux, m_ng), ...
                analysis.spectrum.theory_freqs(m_flux, m_ng), analysis.spectrum.theory_amp_watts(m_flux, m_ng)] = ...
                fit_f_inverse_law(squeeze(analysis.sa.freq(m_flux, m_gate, plotting.f_inverse_start_index:end)),squeeze(analysis.sa.amp_watts(m_flux, m_gate, plotting.f_inverse_start_index:end) ...
                - analysis.sa.amp_carrier_off_watts(m_flux, m_gate, plotting.f_inverse_start_index:end)));
            [~, temp.index] = min(abs(gain_prof.freq - squeeze(analysis.flucs_angle.resonance_fits(m_flux, m_ng, 1))));
            analysis.system_effective_gain.closest_value (m_flux, m_ng) = gain_prof.amp(temp.index);  
            %%%% this is the value of the effective gain of the amp chain
            %%%% (input attenuation + amp gain => vna port to vna port),
            %%%% closest expected at the resonance freq
        end
    end
    analysis.spectrum.theory_amp = convert_watts_to_dBm(analysis.spectrum_theory_amp_watts);
    temp = diff(data.sa.freq, 1, 3);
    analysis.sa.freq_spacing = mean(temp(:));
    if std(temp(:)) ~= 0
        disp('freq spacings are not uniform, but mean taken')
    end
    %%% see equation 36 of https://journals.aps.org/prapplied/pdf/10.1103/PhysRevApplied.15.044009
    %%% for this numerical factor
    [~, temp.input_power_watts] = convert_dBm_to_Vp(input_params.sig_gen.power);
    analysis.spectrum.numerical_factor = (analysis.flucs_angle.resonance_fits(:, :, 2) + analysis.flucs_angle.resonance_fits(:, :, 3))^2 * analysis.flucs_angle.resonance_fits(:, :, 1)^2 ...
        / 2 / analysis.flucs_angle.resonance_fits(:, :, 3)^2 / temp.input_power_watts / analysis.system_effective_gain.closes_value;
    clear temp

    %%% total sigma from 1/f fit is (see eqn. 39 of paper above)
    analysis.spectrum.sigma = sqrt(sum(analysis.spectrum.theory_amp_watts * analysis.sa.freq_spacing / input_params.sa.RBW, 3) .* analysis.spectrum.numerical_factor); 

   %%%% save analysis data
    if plotting.save_analyzed_data     
        save([plotting.mat_file_dir 'only_analysis.mat'],'-regexp', '^(?!(bias_point|data|gain_prof)$).');
    end
end
%% plotting