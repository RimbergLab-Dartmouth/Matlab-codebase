run_params.plot_visible = 0;
run_params.save_data_and_png_param = 1;
run_params.file_name = 'tbd';
run_params.fig_directory = [cd '\plots\'];
run_params.data_directory = [cd '\data\'];
%% bias point and power sweep settings
input_params.ng_value = 0;
input_params.flux_value = 0.53;
input_params.constants.planckant = 6.626e-34;

disp('ensure gain_prof_struct struct and bias_point struct are loaded in workspace')

input_params.power_start_dBm = -65; % at the insert top
input_params.power_stop_dBm = -51; 
[~, input_params.power_start_watts] = convert_dBm_to_Vp(input_params.power_start_dBm);
[~, input_params.power_stop_watts] = convert_dBm_to_Vp(input_params.power_stop_dBm);
input_params.number_power_points = 8;   
input_params.powers_watts = linspace(input_params.power_start_watts, input_params.power_stop_watts, input_params.number_power_points);
input_params.powers_dBm = convert_watts_to_dBm(input_params.powers_watts);
input_params.input_power_step_watts = (input_params.power_stop_watts - input_params.power_start_watts)/(input_params.number_power_points - 1);
input_params.threshold_bifurcation_value_dBm = -54; % power above which bifurcation occurs, probabilistically between 2 amplitude states
[~, input_params.threshold_bifurcation_value_watts] = convert_dBm_to_Vp(input_params.threshold_bifurcation_value_dBm);

%% VNA parameter settings
input_params.vna.rough_average_number = 35;
input_params.vna.rough_center = 5.76e9;
input_params.vna.rough_span = 250e6;
input_params.vna.rough_IF_BW = 10e3;
input_params.vna.rough_number_points = 1601;
input_params.vna.zoom_span = 30e6;
input_params.vna.zoom_IF_BW = 1e3;
input_params.vna.zoom_average_number = 50;
input_params.vna.zoom_number_points = 201;
input_params.vna.electrical_delay = 62.6e-9; 

input_params.q_circle_fit.gamma_int_guess = .2e6;
input_params.q_circle_fit.gamma_ext_guess = 1.2e6;
input_params.q_circle_fit.sigma_guess = .5e6;

%% initialize data arrays
data.rough.freq = zeros(1, input_params.vna.rough_number_points);
data.rough.amp = data.rough.freq;
data.rough.phase = data.rough.phase;

data.zoom.freq = zeros(input_params.number_power_points, input_params.vna.zoom_number_points);
data.zoom.amp = data.zoom.freq;
data.zoom.phase = data.zoom.freq;
data.zoom.real = data.zoom.freq;
data.zoom.imag = data.zoom.freq;

analysis.subtracted_amp = zeros(input_params.number_power_points, input_params.vna.zoom_number_points);
analysis.subtracted_phase = zeros(input_params.number_power_points, input_params.vna.zoom_number_points);

analysis.fits_no_flucs.real = zeros(input_params.number_power_points, input_params.vna.zoom_number_points);
analysis.fits_no_flucs.imag = analysis.fits_no_flucs.real;
analysis.fits_no_flucs.amp = analysis.fits_no_flucs.real;
analysis.fits_no_flucs.phase = analysis.fits_no_flucs.real;
analysis.fits_no_flucs.res_freq = zeros(input_params.number_power_points);
analysis.fits_no_flucs.fit_error = analysis.fits_no_flucs.res_freq;
analysis.fits_no_flucs.gamma_int = analysis.fits_no_flucs.res_freq;
analysis.fits_no_flucs.gamma_ext = analysis.fits_no_flucs.res_freq;

analysis.fits_flucs_no_angle.real = zeros(input_params.number_power_points, input_params.vna.zoom_number_points);
analysis.fits_flucs_no_angle.imag = analysis.fits_flucs_no_angle.real;
analysis.fits_flucs_no_angle.amp = analysis.fits_flucs_no_angle.real;
analysis.fits_flucs_no_angle.phase = analysis.fits_flucs_no_angle.real;
analysis.fits_flucs_no_angle.res_freq = zeros(input_params.number_power_points);
analysis.fits_flucs_no_angle.fit_error = analysis.fits_flucs_no_angle.res_freq;
analysis.fits_flucs_no_angle.gamma_int = analysis.fits_flucs_no_angle.res_freq;
analysis.fits_flucs_no_angle.gamma_ext = analysis.fits_flucs_no_angle.res_freq;
analysis.fits_flucs_no_angle.sigma = analysis.fits_flucs_no_angle.res_freq;

analysis.fits_flucs_and_angle.real = zeros(input_params.number_power_points, input_params.vna.zoom_number_points);
analysis.fits_flucs_and_angle.imag = analysis.fits_with_angle.real;
analysis.fits_flucs_and_angle.amp = analysis.fits_with_angle.real;
analysis.fits_flucs_and_angle.phase = analysis.fits_with_angle.real;
analysis.fits_flucs_and_angle.res_freq = zeros(input_params.number_power_points);
analysis.fits_flucs_and_angle.fit_error = analysis.fits_flucs_and_angle.res_freq;
analysis.fits_flucs_and_angle.gamma_int = analysis.fits_flucs_and_angle.res_freq;
analysis.fits_flucs_and_angle.gamma_ext = analysis.fits_flucs_and_angle.res_freq;
analysis.fits_flucs_and_angle.sigma = analysis.fits_flucs_and_angle.res_freq;
analysis.fits_flucs_and_angle.angle = analysis.fits_flucs_and_angle.res_freq;

%% set VNA 
vna_set_electrical_delay (vna, vna_electrical_delay,1,2);
vna_set_IF_BW(vna, input_params.vna.rough_IF_BW, 1)
vna_set_sweep_points(vna, input_params.vna.rough_number_points ,1)
vna_set_average(vna,input_params.vna.rough_average_number,1,1);
vna_set_center_span(vna, input_params.vna.rough_center, input_params.vna.rough_span,1)
%% set bias point
data.expected_bias_point_params_struct.freq_error = 1e8;
while abs(data.expected_bias_point_params_struct.freq_error) > 5e7
    [data.expected_bias_point_params_struct] = ...
    set_bias_point_using_offset_period_struct(input_params.ng_value,input_params.flux_value, bias_point, 0,1,vna);
end
%% collect rough resonance data
vna_set_power(vna, -65, 1)
vna_turn_output_on(vna)
[data.rough.freq, data.rough.amp] = vna_get_data(vna, 1, 1);
[~, data.rough.phase] = vna_get_data(vna, 1, 2);
[~, min_index] = min(data.rough.amp);
data.rough.resonance_freq = data.freq(min_index);
clear min_index
%% set VNA params for fine scan
vna_set_IF_BW(vna, input_params.vna.zoom_IF_BW, 1)
vna_set_sweep_points(vna, input_params.vna.zoom_number_points ,1)
vna_set_average(vna,input_params.vna.zoom_average_number,1,1);
vna_set_center_span(vna, data.rough.resonance_freq, input_params.vna.zoom_span,1)
%% collect fine resonance data for all powers
for m_power = 1 : input_params.number_power_points
    vna_set_power(vna, input_params.powers_dBm(m_power))
    vna_send_average_trigger(vna);
    [data.zoom.freq(m_power, :), data.zoom.amp(m_power, :)] = vna_get_data(vna, 1, 1);
    [~, data.zoom.phase(m_power, :)] = vna_get_data(vna, 1, 2);
    if m_power == 1
        analysis.interp_gain_amp = interp1(gain_prof_struct.freq, gain_prof_struct.amp, data.zoom.freq(m_power, :), 'pchip');
        analysis.interp_gain_phase = interp1(gain_prof_struct.freq, gain_prof_struct.phase, data.zoom.freq(m_power, :), 'pchip');
    end
    analysis.subtracted_amp(m_power, :) = data.zoom.amp(m_power, :) - analysis.interp_gain_amp;
    analysis.subtracted_phase(m_power, :) = data.zoom.phase(m_power, :) - analysis.interp_gain_phase;
    
    %%%% fit q circle to acquired data with no freq flucs
    [analysis.fits_no_flucs.fit_struct(input_params.m_power)] = ...
            fit_q_circle(analysis.subtracted_amp(m_power, :), ...
                        analysis.subtracted_phase(m_power, :), ...
                        data.zoom.freq(m_power,  :), ...
                        input_params.q_circle_fit.gamma_int_guess, input_params.q_circle_fit.gamma_ext_guess);
                    
    analysis.fits_no_flucs.goodness_fit(m_power) = analysis.fits_no_flucs.fit_struct(input_params.m_power).goodness_fit;
    analysis.fits_no_flucs.res_freq(m_power) = analysis.fits_no_flucs.fit_struct(input_params.m_power).res_freq_fit;
    analysis.fits_no_flucs.gamma_int(m_power) = analysis.fits_no_flucs.fit_struct(input_params.m_power).gamma_int_fit;
    analysis.fits_no_flucs.gamma_ext(m_power) = analysis.fits_no_flucs.fit_struct(input_params.m_power).gamma_ext_fit;
    data.zoom.real(m_power,  :) = analysis.fits_no_flucs.fit_struct(input_params.m_power).data_real;
    data.zoom.imag(m_power,  :) = analysis.fits_no_flucs.fit_struct(input_params.m_power).data_imag;
    analysis.fits_no_flucs.real(m_power,  :) = analysis.fits_no_flucs.fit_struct(input_params.m_power).theory_real;
    analysis.fits_no_flucs.imag(m_power,  :) = analysis.fits_no_flucs.fit_struct(input_params.m_power).theory_imag;  
    
    [temp_lin_mag, temp_phase_radians] = extract_lin_mag_phase_from_real_imag( ...
            analysis.fits_no_flucs.real(m_power, :), ...
            analysis.fits_no_flucs.imag(m_power, :), ...
            data.zoom.freq(m_power, :));
    
    [analysis.fits_no_flucs.amp(m_power, :), ...
        analysis.fits_no_flucs.phase(m_power, :)] = ...
        extract_log_mag_phase_degs(temp_lin_mag, temp_phase_radians);
    
    clear temp_lin_mag ...
          temp_phase_radians
    
      %%%% fit q circle to acquired data with freq flucs, but no angle
    [analysis.fits_flucs_no_angle.fit_struct(input_params.run_number)] = ...
        fit_q_circle_with_freq_flucs(analysis.subtracted_amp(m_power,:), ...
                    analysis.subtracted_phase(m_power,:), ...
                    data.zoom.freq(m_power, :), ...
                    input_params.q_circle_fit.gamma_int_guess, input_params.q_circle_fit.gamma_ext_guess, ...
                    input_params.q_circle_fit.sigma_guess);
                    
    analysis.fits_flucs_no_angle.goodness_fit(m_power) = analysis.fits_flucs_no_angle.fit_struct(input_params.run_number).goodness_fit;
    analysis.fits_flucs_no_angle.res_freq(m_power) = analysis.fits_flucs_no_angle.fit_struct(input_params.run_number).res_freq_fit;
    analysis.fits_flucs_no_angle.gamma_int(m_power) = analysis.fits_flucs_no_angle.fit_struct(input_params.run_number).gamma_int_fit;
    analysis.fits_flucs_no_angle.gamma_ext(m_power) = analysis.fits_flucs_no_angle.fit_struct(input_params.run_number).gamma_ext_fit;
    analysis.fits_flucs_no_angle.sigma(m_power) = analysis.fits_flucs_no_angle.fit_struct(input_params.run_number).sigma_fit;
    analysis.fits_flucs_no_angle.real(m_power, :) = analysis.fits_flucs_no_angle.fit_struct(input_params.run_number).theory_real;
    analysis.fits_flucs_no_angle.imag(m_power, :) = analysis.fits_flucs_no_angle.fit_struct(input_params.run_number).theory_imag;
    
    [temp_lin_mag, temp_phase_radians] = extract_lin_mag_phase_from_real_imag( ...
            analysis.fits_flucs_no_angle.real(m_power, :), ...
            analysis.fits_flucs_no_angle.imag(m_power, :), ...
            data.zoom.freq(m_power, :));
        
    [analysis.fits_flucs_no_angle.amp(m_power, :), ...
        analysis.fits_flucs_no_angle.phase(m_power, :)] = ...
        extract_log_mag_phase_degs(temp_lin_mag, temp_phase_radians);
    
    clear temp_lin_mag ...
          temp_phase_radians
      
      %%%% fit q circle to acquired data, with freq flucs and angle
    [analysis.fits_flucs_and_angle.fit_struct(input_params.run_number)] = ...    
        fit_q_circle_with_freq_flucs_and_angle(analysis.subtracted_amp(m_power,:), ...
                    analysis.subtracted_phase(m_power,:), ...
                    data.zoom.freq(m_power, :), ...
                    input_params.q_circle_fit.gamma_int_guess, input_params.q_circle_fit.gamma_ext_guess, ...
                    input_params.q_circle_fit.sigma_guess);
    analysis.fits_flucs_and_angle.goodness_fit(m_power) = analysis.fits_flucs_and_angle.fit_struct(input_params.run_number).goodness_fit;
    analysis.fits_flucs_and_angle.res_freq(m_power) = analysis.fits_flucs_and_angle.fit_struct(input_params.run_number).res_freq_fit;
    analysis.fits_flucs_and_angle.gamma_int(m_power) = analysis.fits_flucs_and_angle.fit_struct(input_params.run_number).gamma_int_fit;
    analysis.fits_flucs_and_angle.gamma_ext(m_power) = analysis.fits_flucs_and_angle.fit_struct(input_params.run_number).gamma_ext_fit;
    analysis.fits_flucs_and_angle.sigma(m_power) = analysis.fits_flucs_and_angle.fit_struct(input_params.run_number).sigma_fit;
    analysis.fits_flucs_and_angle.angle(m_power) = analysis.fits_flucs_and_angle.fit_struct(input_params.run_number).angle_fit;
    analysis.fits_flucs_and_angle.real(m_power, :) = analysis.fits_flucs_and_angle.fit_struct(input_params.run_number).theory_real;
    analysis.fits_flucs_and_angle.imag(m_power, :) = analysis.fits_flucs_and_angle.fit_struct(input_params.run_number).theory_imag; 

    [temp_lin_mag, temp_phase_radians] = extract_lin_mag_phase_from_real_imag( ...
            analysis.fits_flucs_and_angle.real(m_power, :), ...
            analysis.fits_flucs_and_angle.imag(m_power, :), ...
            data.zoom.freq(m_power, :));
        
    [analysis.fits_flucs_and_angle.amp(m_power, :), ...
        analysis.fits_flucs_and_angle.phase(m_power, :)] = ...
        extract_log_mag_phase_degs(temp_lin_mag, temp_phase_radians);                    
    
    clear temp_lin_mag ...
          temp_phase_radians
      
    %%%%% plot gain profile and raw data
    if run_params.plot_visible == 1
        raw_amp_phase_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    elseif run_params.plot_visible == 0 
        raw_amp_phase_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
    end
    subplot(2, 1, 1)
    plot(gain_prof_struct.freq, gain_prof_struct.amp, 'DisplayName', 'gain profile')
    hold on
    plot(squeeze(data.rough.freq(m_power, :)), ...
            squeeze(data.rough.amp(m_power,:)), ...
            'DisplayName', 'rough')
    plot(squeeze(data.zoom.freq(m_power, :)), ...
            squeeze(data.zoom.amp(m_power,:)), ...
            'DisplayName', 'data')
    plot(expected_freq, min(squeeze(data.zoom.amp(m_power,:))), ...
        'ko', 'markersize', 16, 'linewidth', 4)
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('$\vert S_{21}$(dB)', 'interpreter', 'latex')
    title(['gain profile and data, power = ' num2str(input_params.powers_dBm(m_power)) 'dBm'])
    legend show
    subplot(2, 1, 2)
    plot(gain_prof_struct.freq, gain_prof_struct.phase, 'DisplayName', 'gain profile')
    hold on
    plot(squeeze(data.rough.freq(m_power, :)), ...
            squeeze(data.rough.phase(m_power,:)), ...
            'DisplayName', 'rough')
    plot(squeeze(data.zoom.freq(m_power, :)), ...
            squeeze(data.zoom.phase(m_power,:)), ...
            'DisplayName', 'data')    
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('Phase(S_{21})$(^o)$', 'interpreter', 'latex')
    if run_params.save_data_and_png_param == 1
        save_file_name = [run_params.fig_directory num2str(m_power) ...
            '_ng_' num2str(run_params.ng_value) '_flux_' num2str(run_params.flux_value*1000) 'm_raw_data_' num2str(input_params.powers_dBm(m_power)) 'dBm.png'];
        saveas(raw_amp_phase_figure, save_file_name)
        save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_power) ...
            '_ng_' num2str(run_params.ng_value) '_flux_' num2str(run_params.flux_value*1000) 'm_raw_data_' num2str(input_params.powers_dBm(m_power)) 'dBm.fig'];
    end
    clear raw_amp_phase_figure ...
          save_file_name
    
    %%%% plot q-circles
    if run_params.plot_visible == 1
        q_circle_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    elseif run_params.plot_visible == 0 
        q_circle_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
    end
    subplot(1, 3, 1)
    scatter(squeeze(data.zoom.real(m_power, :)), ...
            squeeze(data.zoom.imag(m_power, :)), ...
            '.', 'markersize', 16, 'linewidth', 3, 'DisplayName', 'data')
    pbaspect([1 1 1 ])
    hold on
    plot(squeeze(analysis.fits_no_flucs.real(m_power, :)), ...
            squeeze(analysis.fits_no_flucs.imag(m_power, :)), ...
            'r', 'DisplayName', ['theory no flucs, error = ' ...
            num2str(analysis.fits_no_flucs.goodness_fit(m_power))])
    plot(squeeze(analysis.fits_flucs_no_angle.real(m_power, :)), ...
            squeeze(analysis.fits_flucs_no_angle.imag(m_power, :)), ...
            'r', 'DisplayName', ['theory, error = ' ...
            num2str(analysis.fits_flucs_no_angle.goodness_fit(m_power))])
    plot(squeeze(analysis.fits_flucs_and_angle.real(m_power, :)), ...
        squeeze(analysis.fits_flucs_and_angle.imag(m_power, :)), ...
        'r', 'DisplayName', ['theory with angle, error = ' ...
        num2str(analysis.fits_flucs_and_angle.goodness_fit(m_power))])
    xlabel('$\Gamma_{real}$', 'interpreter', 'latex')
    ylabel('$\Gamma_{imag}$', 'interpreter', 'latex')
    sgtitle(['resonance circles @ ' num2str(input_params.powers_dBm(m_power)) 'dBm for n_g = ' num2str(run_params.ng_value) 'elns, flux = ' num2str(run_params.flux_value) ...
        '\phi_0.' 13 10 ' no flucs : \omega_0 = ' ...
        num2str(analysis.fits_no_flucs.res_freq(m_power)/1e9) ...
        'GHz, \gamma_{int} = ' ...
        num2str(analysis.fits_no_flucs.gamma_int(m_power)/1e6) ...
        'MHz, \gamma_{ext} = ' ...
        num2str(analysis.fits_no_flucs.gamma_ext(m_power)/1e6) ...
        'MHz' 13 10 ' flucs no angle : \omega_0 = ' ...
        num2str(analysis.fits_flucs_no_angle.res_freq(m_power)/1e9) ...
        'GHz, \gamma_{ext} = ' ...
        num2str(analysis.fits_flucs_no_angle.gamma_ext(m_power)/1e6) ...
        'MHz, \gamma_{int} = ' ...
        num2str(analysis.fits_flucs_no_angle.gamma_int(m_power)/1e6) ...
        'MHz, \sigma_{\omega_0} = ' ...
        num2str(analysis.fits_flucs_no_angle.sigma(m_power)/1e6) ...
        'MHz.' 13 10 'flucs with angle : \omega_0 = ' ...
        num2str(analysis.fits_flucs_and_angle.res_freq(m_power)/1e9) ...
        'GHz, \gamma_{ext} = ' ...
        num2str(analysis.fits_flucs_and_angle.gamma_ext(m_power)/1e6) ...
        'MHz, \gamma_{int} = ' ...
        num2str(analysis.fits_flucs_and_angle.gamma_int(m_power)/1e6) ...
        'MHz, \sigma_{\omega_0} = ' ...
        num2str(analysis.fits_flucs_and_angle.sigma(m_power)/1e6) ...
        'MHz, angle = ' ...
        num2str(analysis.fits_flucs_and_angle.angle(m_power)/1e6) ...
        '^o'], 'interpreter', 'latex');
    
    subplot(1, 3, 2)
    plot(squeeze(data.zoom.freq(m_power, :)), ...
            squeeze(analysis.subtracted_amp(m_power,:)), ...
            '.', 'markersize', 16, 'linewidth', 3, 'DisplayName', 'data')
    hold on
    plot(squeeze(data.zoom.freq(m_power, :))/1e9, ...
            squeeze(analysis.fits_no_flucs.amp(m_power,:)), ...
            'r', 'DisplayName', ['theory no flucs, error = ' ...
            num2str(analysis.fits_no_flucs.goodness_fit(m_power))])
    plot(squeeze(data.zoom.freq(m_power, :))/1e9, ...
            squeeze(analysis.fits_flucs_no_angle.amp(m_power,:)), ...
            'k', 'DisplayName', ['theory with flucs, error = ' ...
            num2str(analysis.fits_flucs_no_angle.goodness_fit(m_power))])  
    plot(squeeze(data.zoom.freq(m_power, :))/1e9, ...
            squeeze(analysis.fits_flucs_and_angle.amp(m_power,:)), ...
            'k', 'DisplayName', ['theory with flucs and angle, error = ' ...
            num2str(analysis.fits_flucs_and_angle.goodness_fit(m_power))])        
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('$\vert S_{21} \vert $(dB)', 'interpreter', 'latex')
    
     subplot(1, 3, 3)
    plot(squeeze(data.zoom.freq(m_power, :)), ...
            squeeze(analysis.subtracted_phase(m_power,:)), ...
            '.', 'markersize', 16, 'linewidth', 3, 'DisplayName', 'data')
    hold on
    plot(squeeze(data.zoom.freq(m_power, :))/1e9, ...
            squeeze(analysis.fits_no_flucs.phase(m_power,:)), ...
            'r', 'DisplayName', ['theory no flucs, error = ' ...
            num2str(analysis.fits_no_flucs.goodness_fit(m_power))])
    plot(squeeze(data.zoom.freq(m_power, :))/1e9, ...
            squeeze(analysis.fits_flucs_no_angle.phase(m_power,:)), ...
            'k', 'DisplayName', ['theory with flucs, error = ' ...
            num2str(analysis.fits_flucs_no_angle.goodness_fit(m_power))])  
    plot(squeeze(data.zoom.freq(m_power, :))/1e9, ...
            squeeze(analysis.fits_flucs_and_angle.phase(m_power,:)), ...
            'k', 'DisplayName', ['theory with flucs and angle, error = ' ...
            num2str(analysis.fits_flucs_and_angle.goodness_fit(m_power))])        
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('Phase(S_{21}) $(^p)$', 'interpreter', 'latex')
    
    if run_params.save_data_and_png_param == 1
        save_file_name = [run_params.fig_directory num2str(m_power) ...
            '_ng_' num2str(run_params.ng_value) '_flux_' num2str(run_params.flux_value*1000) 'm_q_fit_' num2str(input_params.powers_dBm(m_power)) 'dBm.png'];
        saveas(q_circle_figure, save_file_name)
        save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_power) ...
            '_ng_' num2str(run_params.ng_value) '_flux_' num2str(run_params.flux_value*1000) 'm_q_fit_' num2str(input_params.powers_dBm(m_power)) 'dBm.fig'];
        saveas(q_circle_figure, save_file_name)
    end
    close all
    clear q_circle_figure ...
          save_file_name  
end
%% switch off VNA
vna_set_power(vna, -65)
vna_turn_output_off(vna)
%% save data before final analysis
save([run_params.data_directory run_params.file_name '.mat'], '-regexp', '^(?!(run_params)$).')
[~, analysis.min_freq_points_index] = min(data.zoom.amp, [], 2);
for m_power = 1 : size(analysis.min_freq_points_index)
    analysis.min_freq_points (m_power) = data.zoom.freq(m_power, analysis.min_freq_points_index(m_power));
end
analysis.min_freq_points_with_exclusion = analysis.min_freq_points(input_params.powers_dBm < input_params.threshold_bifurcation_value_dBm);
input_params.powers_dBm_with_exclusion = input_params.powers_dBm(input_params.powers_dBm < input_params.threshold_bifurcation_value_dBm);

[analysis.min_freq_vs_power_fit_object, analysis.min_freq_vs_power_linear_fit_params, analysis.min_freq_vs_power_theory_values, ...
    analysis.min_freq_vs_power_fit_error] = fit_linear_cfit(input_params.powers_dBm, analysis.min_freq_points);
confints_95_temp = confint(analysis.min_freq_vs_power_fit_object, 0.95);
analysis.confint_slope = abs(confints_95_temp(1) - analysis.min_freq_vs_power_linear_fit_params(1));
analysis.confint_intercept = abs(confints_95_temp(2) - analysis.min_freq_vs_power_linear_fit_params(2));
clear confints_95_temp

[analysis.min_freq_vs_power_with_exclusion_fit_object, analysis.min_freq_vs_power_with_exclusion_linear_fit_params, ...
    analysis.min_freq_vs_power_with_exclusion_theory_values, analysis.min_freq_vs_power_with_exclusion_fit_error] = ...
    fit_linear_cfit(input_params.powers_dBm_with_exclusion, analysis.min_freq_points_with_exclusion);
confints_95_temp = confint(analysis.min_freq_vs_power_with_exclusion_fit_object, 0.95);
analysis.confint_slope_with_exclusion = abs(confints_95_temp(1) - analysis.min_freq_vs_power_with_exclusion_linear_fit_params(1));
analysis.confint_intercept_with_exclusion = abs(confints_95_temp(2) - analysis.min_freq_vs_power_with_exclusion_linear_fit_params(2));
clear confints_95_temp

%% find attenuation
analysis.kerr_MHz = find_kerr_MHz_ng_flux(input_params.ng_value, input_params.flux_value);
 4*gamma_ext_angle_temp*kerr*1e6/fit_params(1)/h/res_freq_angle_temp/(gamma_ext_angle_temp + gamma_int_angle_temp)^2;
analysis.attenuation = 4*analysis.kerr_MHz*1e6*analysis.fits_flucs_and_angle.gamma_ext(1)/planck_constplanck_const/analysis.fits_flucs_and_angle.res_freq(1)/ ...
    (analysis.fits_flucs_and_angle.gamma_int(1) + analysis.fits_flucs_and_angle.gamma_ext(1))^2/analysis.min_freq_vs_power_linear_fit_params(1);    %%%% see eq. (3.17) of Bhar thesis
analysis.attenuation_with_exclusion = 4*analysis.kerr_MHz*1e6*analysis.fits_flucs_and_angle.gamma_ext(1)/input_params.constants.planck/analysis.fits_flucs_and_angle.res_freq(1)/ ...
    (analysis.fits_flucs_and_angle.gamma_int(1) + analysis.fits_flucs_and_angle.gamma_ext(1))^2/analysis.min_freq_vs_power_with_exclusion_linear_fit_params(1);
analysis.attenuation_dB = 10*log10(analysis.attenuation);
analysis.attenuation_with_exclusion_dB = 10*log10(analysis.attenuation_with_exclusion);

analysis.attenuation_error = 4*analysis.kerr_MHz*1e6*analysis.fits_flucs_and_angle.gamma_ext(1)/input_params.constants.planck/analysis.fits_flucs_and_angle.res_freq(1)/ ...
    (analysis.fits_flucs_and_angle.gamma_int(1) + analysis.fits_flucs_and_angle.gamma_ext(1))^2/analysis.confint_slope;
analysis.attenuation_with_exclusion_error =  4*analysis.kerr_MHz*1e6*analysis.fits_flucs_and_angle.gamma_ext(1)/input_params.constants.planck/analysis.fits_flucs_and_angle.res_freq(1)/ ...
    (analysis.fits_flucs_and_angle.gamma_int(1) + analysis.fits_flucs_and_angle.gamma_ext(1))^2/analysis.confint_slope_with_exclusion;
analysis.attenuation_error_dB = 10*log10(analysis.attenuation_error);
analysis.attenuation_with_exclusion_error_dB = 10*log10(analysis.attenuation_with_exclusion_error);
%% plot attenuation finder plot
if run_params.plot_visible == 1
    min_freq_vs_power_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
elseif run_params.plot_visible == 0 
    min_freq_vs_power_figure= figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
end
errorbar(input_params.powers_dBm, analysis.min_freq_points, analysis.fits_flucs_and_angle.sigma(1), 'x', 'MarkerSize', 16, 'DisplayName', 'Data')
hold on
plot(input_params.powers_watts/1e9, analysis.min_freq_vs_power_theory_values/1e9, 'r', 'LineWidth', 3, 'DisplayName', 'Fit all')
plot(input_params.powers_watts/1e9, analysis.min_freq_vs_power_with_exclusion_theory_values/1e9, 'b', 'LineWidth', 3, 'DisplayName', 'Fit below bifurcation')
xlabel('$P_{\mathrm{sg}}(nW)', 'interpreter', 'latex')
ylabel('$\omega_0^{\mathrm{(Kerr)}}', 'interpreter', 'latex')
annotation('textbox', [0.3, 0.65, 0.5, 0.3], 'String', ['$K/2\pi$ = ' num2str(analysis.kerr_MHz*1e3) 'kHz'], 'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 42)
annotation('textbox', [0.75, 0.05, 0.5, 0.3], 'String', ['$(n_g, \Phi_{\mathrm{ext}})$ = ' 13 10 '(' num2str(input_params.ng_value) ', ' ...
    num2str(input_params.flux_value) '$\Phi_0$)'], 'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 42)
annotation('textbox', [0.1, 0.05, 0.5, 0.3], 'String', ['Slope = ' num2str(analysis.min_freq_vs_power_linear_fit_params(1) *1e6) 'kHz/nW'], ...
    'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'r')
annotation('textbox', [0.1, 0.15, 0.5, 0.3], 'String', ['Slope = ' num2str(analysis.min_freq_vs_power_linear_fit_params(1) *1e6) 'kHz/nW'], ...
    'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'b')
title(['Attenuation = ' num2str(analysis.attenuation_dB) '$\pm' num2str(analysis.attenuation_error_dB) 'dB' 13 10 ...
    'Attenuation with exclusion = ' num2str(analysis.attenuation_with_exclusion_dB) '$\pm' num2str(analysis.attenuation_with_exclusion_error_dB) 'dB'])
if run_params.save_data_and_png_param == 1
    save_file_name = [run_params.fig_directory ...
        '_ng_' num2str(run_params.ng_value) '_flux_' num2str(run_params.flux_value*1000) 'm_attenuation_finder.png'];
    saveas(q_circle_figure, save_file_name)
    save_file_name = [run_params.fig_directory '\fig_files\' ...
        '_ng_' num2str(run_params.ng_value) '_flux_' num2str(run_params.flux_value*1000) 'm_attenuation_finder.fig'];
    saveas(q_circle_figure, save_file_name)
end
close all
clear q_circle_figure ...
      save_file_name  