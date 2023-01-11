connect_instruments
addpath('\\dartfs-hpc\rc\lab\R\RimbergA\cCPT_NR_project\Bhar_measurements\Alazar_board_apis')

%%% switch off all outputs %%%%
n5183b_toggle_output(keysight_sg, 'off')
e8257c_toggle_output(e8257c_sig_gen, 'off')
n5183b_toggle_pulse_mod(keysight_sg, 'off')
n5183b_toggle_modulation(keysight_sg, 'off')
n5183b_toggle_pulse_mod(e8257c_sig_gen, 'off')
n5183b_toggle_modulation(e8257c_sig_gen, 'off')
%%% turns off AWG only if a new sequence needs to be generated or if it's the first detuning at this bias point, power combo. if using
%%% previous sequence, AWG stays on throughout
if run_params.awg.files_generation_param == 1 || m_detuning == run_params.detuning_point_start
    awg_toggle_output(awg,'off',1)
    awg_toggle_output(awg,'off',2)
    awg_run_output_channel_off(awg,'stop')
    awg_change_directory(awg, '/')
    awg_file_list = awg_list_files(awg);
    if ~contains(awg_file_list, run_params.awg_switching_directory_name)
        awg_create_directory(awg, run_params.awg_switching_directory_name)
    end
    awg_change_directory(awg, run_params.awg_switching_directory_name)
    awg_file_list = awg_list_files(awg);
    if ~contains(awg_file_list, run_params.awg_directory(end -7:end))
        awg_create_directory(awg, run_params.awg_directory(end-7:end))
    end
    awg_change_directory(awg, run_params.awg_directory)
    clear awg_file_list
end
%% set bias point and record set value
if bias_set_param == 1
    disp('setting bias point DC voltage')
    if run_params.set_with_pre_recorded 
        [output_bias_point_struct] = ...
            set_bias_point_using_offset_period_check_with_prerecorded (run_params.ng_1_value, run_params.flux_1_value, bias_point, run_params.pre_recorded_struct,1,vna);
    else
        [output_bias_point_struct] = ...
            set_bias_point_using_offset_period_struct (run_params.ng_1_value, run_params.flux_1_value, bias_point, 0,1,vna);
    end
    data.peripheral.flux_voltage_output (m_power, m_flux, m_gate) = output_bias_point_struct.desired_flux_voltage;
    data.peripheral.gate_voltage_output (m_power, m_flux, m_gate) = output_bias_point_struct.desired_gate_voltage;
    data.peripheral.expected_freq (m_power, m_flux, m_gate) = output_bias_point_struct.expected_freq;
    data.peripheral.freq_error (m_power, m_flux, m_gate) = output_bias_point_struct.freq_error;
    daq_handle=daq.createSession('ni');
    addAnalogOutputChannel(daq_handle,'Dev1','ao0','Voltage');
    addAnalogOutputChannel(daq_handle,'Dev1','ao1','Voltage');
    outputSingleScan(daq_handle,[output_bias_point_struct.desired_gate_voltage output_bias_point_struct.desired_flux_voltage]);
    disp(['bias set to gate = ' num2str(run_params.ng_1_value) ', flux = ' num2str(run_params.flux_1_value)])
    release(daq_handle);
    clear daq_handle ...
          output_bias_point_struct
else
    disp('skipping setting bias point DC voltage')
end
%% acquire VNA data at single photon levels
if vna_data_acquisition == 1
    disp('capturing VNA data at single photon power')
    switch_vna_measurement(ps_2)
    pause(2)
    vna_set_power(vna, -65, 1)
    vna_set_electrical_delay(vna, input_params.vna.electrical_delay, 1, 2);
    vna_turn_output_on(vna)
    vna_set_IF_BW(vna, input_params.vna.rough_IF_BW, 1)
    vna_set_sweep_points(vna, input_params.vna.rough_number_points, 1)
    vna_set_center_span(vna, input_params.vna.rough_center, input_params.vna.rough_span, 1)
    vna_send_average_trigger(vna);
    [data.vna.single_photon.rough.freq(m_power, m_flux, m_gate, :), ...
            data.vna.single_photon.rough.amp(m_power, m_flux, m_gate,:)] = ...
            vna_get_data(vna, 1, 1);
    [~, data.vna.single_photon.rough.phase(m_power, m_flux, m_gate,:)] = ...
            vna_get_data(vna, 1, 2);
    [~,manual_index] = min(squeeze(data.vna.single_photon.rough.amp(m_power, m_flux, m_gate,:)) ...
            - gain_prof.amp');
    rough_resonance = squeeze(data.vna.single_photon.rough.freq(m_power, m_flux, m_gate, manual_index));
    vna_set_center_span(vna,rough_resonance,input_params.vna.zoom_scan_span,1);
    clear manual_index rough_resonance
    vna_set_IF_BW(vna, input_params.vna.IF_BW, 1)
    vna_set_average(vna, input_params.vna.average_number, 1, 1);
    vna_set_sweep_points(vna, input_params.vna.number_points, 1);
    vna_send_average_trigger(vna);
    [data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :), ...
            data.vna.single_photon.fine.amp(m_power, m_flux, m_gate,:)] = ...
            vna_get_data(vna, 1, 1);
    [~, data.vna.single_photon.fine.phase(m_power, m_flux, m_gate,:)] = ...
            vna_get_data(vna, 1, 2);
    pause(3);
    vna_turn_output_off(vna)
    %% fit VNA data at single photon powers
    analysis.vna.single_photon.interp_gain_amp(m_power, m_flux, m_gate, :) = ...
            interp1(gain_prof.freq, gain_prof.amp, ...
            data.vna.single_photon.fine.freq(m_power, m_flux, m_gate,:), 'pchip');
    analysis.vna.single_photon.interp_gain_phase(m_power, m_flux, m_gate, :) = ...
            interp1(gain_prof.freq, gain_prof.phase, ...
            data.vna.single_photon.fine.freq(m_power, m_flux, m_gate,:), 'pchip');
    analysis.vna.single_photon.subtracted_amp(m_power, m_flux, m_gate,:) = ...
            data.vna.single_photon.fine.amp(m_power, m_flux, m_gate,:) - ...
            analysis.vna.single_photon.interp_gain_amp(m_power, m_flux, m_gate,:);
    analysis.vna.single_photon.subtracted_phase(m_power, m_flux, m_gate,:) = ...
            data.vna.single_photon.fine.phase(m_power, m_flux, m_gate,:) - ...
            analysis.vna.single_photon.interp_gain_phase(m_power, m_flux, m_gate,:);
        
    [analysis.vna.single_photon.fits_no_flucs.fit_struct(input_params.run_number)] = ...
            fit_q_circle(analysis.vna.single_photon.subtracted_amp(m_power, m_flux, m_gate,:), ...
                        analysis.vna.single_photon.subtracted_phase(m_power, m_flux, m_gate,:), ...
                        data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :), ...
                        input_params.q_circle_fit.gamma_int_guess, input_params.q_circle_fit.gamma_ext_guess);
                    
    analysis.vna.single_photon.fits_no_flucs.goodness_fit(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_no_flucs.fit_struct(input_params.run_number).goodness_fit;
    analysis.vna.single_photon.fits_no_flucs.res_freq(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_no_flucs.fit_struct(input_params.run_number).res_freq_fit;
    analysis.vna.single_photon.fits_no_flucs.gamma_int(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_no_flucs.fit_struct(input_params.run_number).gamma_int_fit;
    analysis.vna.single_photon.fits_no_flucs.gamma_ext(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_no_flucs.fit_struct(input_params.run_number).gamma_ext_fit;
    data.vna.single_photon.fine.real(m_power, m_flux, m_gate, :) = analysis.vna.single_photon.fits_no_flucs.fit_struct(input_params.run_number).data_real;
    data.vna.single_photon.fine.imag(m_power, m_flux, m_gate, :) = analysis.vna.single_photon.fits_no_flucs.fit_struct(input_params.run_number).data_imag;
    analysis.vna.single_photon.fits_no_flucs.real(m_power, m_flux, m_gate, :) = analysis.vna.single_photon.fits_no_flucs.fit_struct(input_params.run_number).theory_real;
    analysis.vna.single_photon.fits_no_flucs.imag(m_power, m_flux, m_gate, :) = analysis.vna.single_photon.fits_no_flucs.fit_struct(input_params.run_number).theory_imag;        
    
    [temp_lin_mag, temp_phase_radians] = extract_lin_mag_phase_from_real_imag( ...
            analysis.vna.single_photon.fits_no_flucs.real(m_power, m_flux, m_gate, :), ...
            analysis.vna.single_photon.fits_no_flucs.imag(m_power, m_flux, m_gate, :), ...
            data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :));
    
    [analysis.vna.single_photon.fits_no_flucs.amp(m_power, m_flux, m_gate, :), ...
        analysis.vna.single_photon.fits_no_flucs.phase(m_power, m_flux, m_gate, :)] = ...
        extract_log_mag_phase_degs(temp_lin_mag, temp_phase_radians);
    
    clear temp_lin_mag ...
          temp_phase_radians
    
    [analysis.vna.single_photon.fits_flucs_no_angle.fit_struct(input_params.run_number)] = ...
            fit_q_circle_with_freq_flucs(analysis.vna.single_photon.subtracted_amp(m_power, m_flux, m_gate,:), ...
                        analysis.vna.single_photon.subtracted_phase(m_power, m_flux, m_gate,:), ...
                        data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :), ...
                        input_params.q_circle_fit.gamma_int_guess, input_params.q_circle_fit.gamma_ext_guess, ...
                        input_params.q_circle_fit.sigma_guess);
                    
    analysis.vna.single_photon.fits_flucs_no_angle.goodness_fit(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_no_angle.fit_struct(input_params.run_number).goodness_fit;
    analysis.vna.single_photon.fits_flucs_no_angle.res_freq(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_no_angle.fit_struct(input_params.run_number).res_freq_fit;
    analysis.vna.single_photon.fits_flucs_no_angle.gamma_int(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_no_angle.fit_struct(input_params.run_number).gamma_int_fit;
    analysis.vna.single_photon.fits_flucs_no_angle.gamma_ext(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_no_angle.fit_struct(input_params.run_number).gamma_ext_fit;
    analysis.vna.single_photon.fits_flucs_no_angle.sigma(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_no_angle.fit_struct(input_params.run_number).sigma_fit;
    analysis.vna.single_photon.fits_flucs_no_angle.real(m_power, m_flux, m_gate, :) = analysis.vna.single_photon.fits_flucs_no_angle.fit_struct(input_params.run_number).theory_real;
    analysis.vna.single_photon.fits_flucs_no_angle.imag(m_power, m_flux, m_gate, :) = analysis.vna.single_photon.fits_flucs_no_angle.fit_struct(input_params.run_number).theory_imag;
    
    [temp_lin_mag, temp_phase_radians] = extract_lin_mag_phase_from_real_imag( ...
            analysis.vna.single_photon.fits_flucs_no_angle.real(m_power, m_flux, m_gate, :), ...
            analysis.vna.single_photon.fits_flucs_no_angle.imag(m_power, m_flux, m_gate, :), ...
            data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :));
        
    [analysis.vna.single_photon.fits_flucs_no_angle.amp(m_power, m_flux, m_gate, :), ...
        analysis.vna.single_photon.fits_flucs_no_angle.phase(m_power, m_flux, m_gate, :)] = ...
        extract_log_mag_phase_degs(temp_lin_mag, temp_phase_radians);
    
    clear temp_lin_mag ...
          temp_phase_radians
                    
    [analysis.vna.single_photon.fits_flucs_and_angle.fit_struct(input_params.run_number)] = ...    
            fit_q_circle_with_freq_flucs_and_angle(analysis.vna.single_photon.subtracted_amp(m_power, m_flux, m_gate,:), ...
                        analysis.vna.single_photon.subtracted_phase(m_power, m_flux, m_gate,:), ...
                        data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :), ...
                        input_params.q_circle_fit.gamma_int_guess, input_params.q_circle_fit.gamma_ext_guess, ...
                        input_params.q_circle_fit.sigma_guess);
    
    analysis.vna.single_photon.fits_flucs_and_angle.goodness_fit(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_and_angle.fit_struct(input_params.run_number).goodness_fit;
    analysis.vna.single_photon.fits_flucs_and_angle.res_freq(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_and_angle.fit_struct(input_params.run_number).res_freq_fit;
    analysis.vna.single_photon.fits_flucs_and_angle.gamma_int(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_and_angle.fit_struct(input_params.run_number).gamma_int_fit;
    analysis.vna.single_photon.fits_flucs_and_angle.gamma_ext(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_and_angle.fit_struct(input_params.run_number).gamma_ext_fit;
    analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_and_angle.fit_struct(input_params.run_number).sigma_fit;
    analysis.vna.single_photon.fits_flucs_and_angle.angle(m_power, m_flux, m_gate) = analysis.vna.single_photon.fits_flucs_and_angle.fit_struct(input_params.run_number).angle_fit;
    analysis.vna.single_photon.fits_flucs_and_angle.real(m_power, m_flux, m_gate, :) = analysis.vna.single_photon.fits_flucs_and_angle.fit_struct(input_params.run_number).theory_real;
    analysis.vna.single_photon.fits_flucs_and_angle.imag(m_power, m_flux, m_gate, :) = analysis.vna.single_photon.fits_flucs_and_angle.fit_struct(input_params.run_number).theory_imag; 

    [temp_lin_mag, temp_phase_radians] = extract_lin_mag_phase_from_real_imag( ...
            analysis.vna.single_photon.fits_flucs_and_angle.real(m_power, m_flux, m_gate, :), ...
            analysis.vna.single_photon.fits_flucs_and_angle.imag(m_power, m_flux, m_gate, :), ...
            data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :));
        
    [analysis.vna.single_photon.fits_flucs_and_angle.amp(m_power, m_flux, m_gate, :), ...
        analysis.vna.single_photon.fits_flucs_and_angle.phase(m_power, m_flux, m_gate, :)] = ...
        extract_log_mag_phase_degs(temp_lin_mag, temp_phase_radians);                    
    
    clear temp_lin_mag ...
          temp_phase_radians
    %% Plot and save q-circle data at single photon powers
    if run_params.plot_visible == 1
        raw_amp_phase_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    elseif run_params.plot_visible == 0 
        raw_amp_phase_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
    end
    subplot(2, 1, 1)
    plot(gain_prof.freq, gain_prof.amp, 'DisplayName', 'gain profile')
    hold on
    plot(squeeze(data.vna.single_photon.rough.freq(m_power, m_flux, m_gate, :)), ...
            squeeze(data.vna.single_photon.rough.amp(m_power, m_flux, m_gate,:)), ...
            'DisplayName', 'rough')
    plot(squeeze(data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :)), ...
            squeeze(data.vna.single_photon.fine.amp(m_power, m_flux, m_gate,:)), ...
            'DisplayName', 'data')
    plot(squeeze(data.peripheral.expected_freq (m_power, m_bias_point)), min(squeeze(data.vna.single_photon.fine.amp(m_power, m_flux, m_gate,:))), ...
        'ko', 'markersize', 4, 'linewidth', 4)
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('$\vert S_{21} \vert$(dB)', 'interpreter', 'latex')
    title('gain profile log mag single photon drive')
    legend show
    subplot(2, 1, 2)
    plot(gain_prof.freq, gain_prof.phase, 'DisplayName', 'gain profile')
    hold on
    plot(squeeze(data.vna.single_photon.rough.freq(m_power, m_flux, m_gate, :)), ...
            squeeze(data.vna.single_photon.rough.phase(m_power, m_flux, m_gate,:)), ...
            'DisplayName', 'rough')
    plot(squeeze(data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :)), ...
            squeeze(data.vna.single_photon.fine.phase(m_power, m_flux, m_gate,:)), ...
            'DisplayName', 'data')    
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('Phase($S_{21})(^o)$', 'interpreter', 'latex')
    if run_params.save_data_and_png_param == 1
        save_file_name = [run_params.fig_directory num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) ...
            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_gain_prof_-65dBm.png'];
        saveas(raw_amp_phase_figure, save_file_name)
        save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) ...
            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_gain_prof_-65dBm.fig'];
        saveas(raw_amp_phase_figure, save_file_name)
    end
    clear raw_amp_phase_figure ...
          save_file_name
    
    if run_params.plot_visible == 1
        q_circle_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    elseif run_params.plot_visible == 0 
        q_circle_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
    end
    subplot(1, 3, 1)
    plot(squeeze(data.vna.single_photon.fine.real(m_power, m_flux, m_gate, :)), ...
            squeeze(data.vna.single_photon.fine.imag(m_power, m_flux, m_gate, :)), ...
            'o', 'markersize', 4, 'linewidth', 3, 'DisplayName', 'data')
    pbaspect([1 1 1 ])
    hold on
    plot(squeeze(analysis.vna.single_photon.fits_no_flucs.real(m_power, m_flux, m_gate, :)), ...
            squeeze(analysis.vna.single_photon.fits_no_flucs.imag(m_power, m_flux, m_gate, :)), ...
            'r', 'DisplayName', ['theory no flucs, error = ' ...
            num2str(analysis.vna.single_photon.fits_no_flucs.goodness_fit(m_power, m_flux, m_gate))])
    plot(squeeze(analysis.vna.single_photon.fits_flucs_no_angle.real(m_power, m_flux, m_gate, :)), ...
            squeeze(analysis.vna.single_photon.fits_flucs_no_angle.imag(m_power, m_flux, m_gate, :)), ...
            'b', 'DisplayName', ['theory, error = ' ...
            num2str(analysis.vna.single_photon.fits_flucs_no_angle.goodness_fit(m_power, m_flux, m_gate))])
    plot(squeeze(analysis.vna.single_photon.fits_flucs_and_angle.real(m_power, m_flux, m_gate, :)), ...
        squeeze(analysis.vna.single_photon.fits_flucs_and_angle.imag(m_power, m_flux, m_gate, :)), ...
        'k', 'DisplayName', ['theory with angle, error = ' ...
        num2str(analysis.vna.single_photon.fits_flucs_and_angle.goodness_fit(m_power, m_flux, m_gate))])
    xlabel('$\Gamma_{\mathrm{real}}$', 'interpreter', 'latex')
    ylabel('$\Gamma_{\mathrm{\mathrm{imag}}}$', 'interpreter', 'latex')
    sgtitle(['resonance circles @ -65dBm for $n_g$ = ' num2str(run_params.ng_1_value) 'elns, flux = ' num2str(run_params.flux_1_value) ...
        '$\phi_0$.' 13 10 ' no flucs : $\omega_0$ = ' ...
        num2str(analysis.vna.single_photon.fits_no_flucs.res_freq(m_power, m_flux, m_gate)/1e9) ...
        'GHz, $\kappa_{\mathrm{int}}$ = ' ...
        num2str(analysis.vna.single_photon.fits_no_flucs.gamma_int(m_power, m_flux, m_gate)/1e6) ...
        'MHz, $\kappa_{\mathrm{ext}}$ = ' ...
        num2str(analysis.vna.single_photon.fits_no_flucs.gamma_ext(m_power, m_flux, m_gate)/1e6) ...
        'MHz' 13 10 ' flucs no angle : $\omega_0$ = ' ...
        num2str(analysis.vna.single_photon.fits_flucs_no_angle.res_freq(m_power, m_flux, m_gate)/1e9) ...
        'GHz, $\kappa_{\mathrm{ext}}$ = ' ...
        num2str(analysis.vna.single_photon.fits_flucs_no_angle.gamma_ext(m_power, m_flux, m_gate)/1e6) ...
        'MHz, $\kappa_{\mathrm{int}}$ = ' ...
        num2str(analysis.vna.single_photon.fits_flucs_no_angle.gamma_int(m_power, m_flux, m_gate)/1e6) ...
        'MHz, $\sigma_{\omega_0}$ = ' ...
        num2str(analysis.vna.single_photon.fits_flucs_no_angle.sigma(m_power, m_flux, m_gate)/1e6) ...
        'MHz.' 13 10 'flucs with angle : $\omega_0$ = ' ...
        num2str(analysis.vna.single_photon.fits_flucs_and_angle.res_freq(m_power, m_flux, m_gate)/1e9) ...
        'GHz, $\kappa_{\mathrm{ext}}$ = ' ...
        num2str(analysis.vna.single_photon.fits_flucs_and_angle.gamma_ext(m_power, m_flux, m_gate)/1e6) ...
        'MHz, $\kappa_{\mathrm{int}}$ = ' ...
        num2str(analysis.vna.single_photon.fits_flucs_and_angle.gamma_int(m_power, m_flux, m_gate)/1e6) ...
        'MHz, $\sigma_{\omega_0}$ = ' ...
        num2str(analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)/1e6) ...
        'MHz, angle = ' ...
        num2str(analysis.vna.single_photon.fits_flucs_and_angle.angle(m_power, m_flux, m_gate)/1e6) ...
        '$^\circ$'], 'interpreter', 'latex');
    
    subplot(1, 3, 2)
    plot(squeeze(data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.single_photon.subtracted_amp(m_power, m_flux, m_gate,:)), ...
            'o', 'markersize', 4, 'linewidth', 3, 'DisplayName', 'data')
    hold on
    plot(squeeze(data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.single_photon.fits_no_flucs.amp(m_power, m_flux, m_gate,:)), ...
            'r', 'DisplayName', ['theory no flucs, error = ' ...
            num2str(analysis.vna.single_photon.fits_no_flucs.goodness_fit(m_power, m_flux, m_gate))])
    plot(squeeze(data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.single_photon.fits_flucs_no_angle.amp(m_power, m_flux, m_gate,:)), ...
            'b', 'DisplayName', ['theory with flucs, error = ' ...
            num2str(analysis.vna.single_photon.fits_flucs_no_angle.goodness_fit(m_power, m_flux, m_gate))])  
    plot(squeeze(data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.single_photon.fits_flucs_and_angle.amp(m_power, m_flux, m_gate,:)), ...
            'k', 'DisplayName', ['theory with flucs and angle, error = ' ...
            num2str(analysis.vna.single_photon.fits_flucs_and_angle.goodness_fit(m_power, m_flux, m_gate))])        
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('$\vert S_{21} \vert $(dB)', 'interpreter', 'latex')
    legend show 
    
     subplot(1, 3, 3)
    plot(squeeze(data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.single_photon.subtracted_phase(m_power, m_flux, m_gate,:)), ...
            'o', 'markersize', 4, 'linewidth', 3, 'DisplayName', 'data')
    hold on
    plot(squeeze(data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.single_photon.fits_no_flucs.phase(m_power, m_flux, m_gate,:)), ...
            'r', 'DisplayName', ['theory no flucs, error = ' ...
            num2str(analysis.vna.single_photon.fits_no_flucs.goodness_fit(m_power, m_flux, m_gate))])
    plot(squeeze(data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.single_photon.fits_flucs_no_angle.phase(m_power, m_flux, m_gate,:)), ...
            'b', 'DisplayName', ['theory with flucs, error = ' ...
            num2str(analysis.vna.single_photon.fits_flucs_no_angle.goodness_fit(m_power, m_flux, m_gate))])  
    plot(squeeze(data.vna.single_photon.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.single_photon.fits_flucs_and_angle.phase(m_power, m_flux, m_gate,:)), ...
            'k', 'DisplayName', ['theory with flucs and angle, error = ' ...
            num2str(analysis.vna.single_photon.fits_flucs_and_angle.goodness_fit(m_power, m_flux, m_gate))])        
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('Phase($S_{21}$) $(^\circ)$', 'interpreter', 'latex')
    
    if run_params.save_data_and_png_param == 1
        save_file_name = [run_params.fig_directory num2str(m_power) '_' num2str(m_bias_point) ...
            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_q_fit_-65dBm.png'];
        saveas(q_circle_figure, save_file_name)
        save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_power) '_' num2str(m_bias_point) ...
            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_q_fit_-65dBm.fig'];
        saveas(q_circle_figure, save_file_name)
    end
    close all
    clear q_circle_figure ...
          save_file_name
else
    disp('skipping single photon power VNA capture')
end
%% Set resonance freq
if res_freq_recorder == 1
    res_freq = analysis.vna.single_photon.fits_flucs_and_angle.res_freq(m_power, m_flux, m_gate);
end
%% Acquire VNA data at desired power
if vna_data_acquisition == 1
    disp('capturing VNA data at desired power')
    switch_vna_measurement(ps_2)
    pause(2)
    vna_set_power(vna, run_params.vna.power, 1)
    vna_set_electrical_delay(vna, input_params.vna.electrical_delay, 1, 2);
    vna_turn_output_on(vna)
    vna_set_IF_BW(vna, input_params.vna.rough_IF_BW, 1)
    vna_set_sweep_points(vna, input_params.vna.rough_number_points, 1)
    vna_set_center_span(vna, input_params.vna.rough_center, input_params.vna.rough_span, 1)
    vna_send_average_trigger(vna);
    [data.vna.actual_power.rough.freq(m_power, m_flux, m_gate, :), ...
            data.vna.actual_power.rough.amp(m_power, m_flux, m_gate,:)] = ...
            vna_get_data(vna, 1, 1);
    [~, data.vna.actual_power.rough.phase(m_power, m_flux, m_gate,:)] = ...
            vna_get_data(vna, 1, 2);
    [~,manual_index] = min(squeeze(data.vna.actual_power.rough.amp(m_power, m_flux, m_gate,:)) ...
            - gain_prof.amp');
    rough_resonance = data.vna.actual_power.rough.freq(m_power, m_flux, m_gate, manual_index);
    vna_set_center_span(vna,rough_resonance,input_params.vna.zoom_scan_span,1);
    clear manual_index rough_resonance
    vna_set_IF_BW(vna, input_params.vna.IF_BW, 1)
    vna_set_average(vna, input_params.vna.average_number, 1, 1);
    vna_set_sweep_points(vna, input_params.vna.number_points, 1);
    vna_send_average_trigger(vna);
    [data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :), ...
            data.vna.actual_power.fine.amp(m_power, m_flux, m_gate,:)] = ...
            vna_get_data(vna, 1, 1);
    [~, data.vna.actual_power.fine.phase(m_power, m_flux, m_gate,:)] = ...
            vna_get_data(vna, 1, 2);
    pause(3);
    vna_set_power(vna, run_params.vna.power, 1)
    vna_turn_output_off(vna)
    %% fit VNA data at desired power
    analysis.vna.actual_power.interp_gain_amp(m_power, m_flux, m_gate, :) = ...
            interp1(gain_prof.freq, gain_prof.amp, ...
            data.vna.actual_power.fine.freq(m_power, m_flux, m_gate,:), 'pchip');
    analysis.vna.actual_power.interp_gain_phase(m_power, m_flux, m_gate, :) = ...
            interp1(gain_prof.freq, gain_prof.phase, ...
            data.vna.actual_power.fine.freq(m_power, m_flux, m_gate,:), 'pchip');
    analysis.vna.actual_power.subtracted_amp(m_power, m_flux, m_gate,:) = ...
            data.vna.actual_power.fine.amp(m_power, m_flux, m_gate,:) - ...
            analysis.vna.actual_power.interp_gain_amp(m_power, m_flux, m_gate,:);
    analysis.vna.actual_power.subtracted_phase(m_power, m_flux, m_gate,:) = ...
            data.vna.actual_power.fine.phase(m_power, m_flux, m_gate,:) - ...
            analysis.vna.actual_power.interp_gain_phase(m_power, m_flux, m_gate,:);
        
    [analysis.vna.actual_power.fits_no_flucs.fit_struct(input_params.run_number)] = ...
            fit_q_circle(analysis.vna.actual_power.subtracted_amp(m_power, m_flux, m_gate,:), ...
                        analysis.vna.actual_power.subtracted_phase(m_power, m_flux, m_gate,:), ...
                        data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :), ...
                        input_params.q_circle_fit.gamma_int_guess, input_params.q_circle_fit.gamma_ext_guess);
                    
    analysis.vna.actual_power.fits_no_flucs.goodness_fit(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_no_flucs.fit_struct(input_params.run_number).goodness_fit;
    analysis.vna.actual_power.fits_no_flucs.res_freq(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_no_flucs.fit_struct(input_params.run_number).res_freq_fit;
    analysis.vna.actual_power.fits_no_flucs.gamma_int(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_no_flucs.fit_struct(input_params.run_number).gamma_int_fit;
    analysis.vna.actual_power.fits_no_flucs.gamma_ext(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_no_flucs.fit_struct(input_params.run_number).gamma_ext_fit;
    data.vna.actual_power.fine.real(m_power, m_flux, m_gate, :) = analysis.vna.actual_power.fits_no_flucs.fit_struct(input_params.run_number).data_real;
    data.vna.actual_power.fine.imag(m_power, m_flux, m_gate, :) = analysis.vna.actual_power.fits_no_flucs.fit_struct(input_params.run_number).data_imag;
    analysis.vna.actual_power.fits_no_flucs.real(m_power, m_flux, m_gate, :) = analysis.vna.actual_power.fits_no_flucs.fit_struct(input_params.run_number).theory_real;
    analysis.vna.actual_power.fits_no_flucs.imag(m_power, m_flux, m_gate, :) = analysis.vna.actual_power.fits_no_flucs.fit_struct(input_params.run_number).theory_imag;                    
                    
    [temp_lin_mag, temp_phase_radians] = extract_lin_mag_phase_from_real_imag( ...
            analysis.vna.actual_power.fits_no_flucs.real(m_power, m_flux, m_gate, :), ...
            analysis.vna.actual_power.fits_no_flucs.imag(m_power, m_flux, m_gate, :), ...
            data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :));
        
    [analysis.vna.actual_power.fits_no_flucs.amp(m_power, m_flux, m_gate, :), ...
        analysis.vna.actual_power.fits_no_flucs.phase(m_power, m_flux, m_gate, :)] = ...
        extract_log_mag_phase_degs(temp_lin_mag, temp_phase_radians);
    
    clear temp_lin_mag ...
          temp_phase_radians
                    
    [analysis.vna.actual_power.fits_flucs_no_angle.fit_struct(input_params.run_number)] = ...
            fit_q_circle_with_freq_flucs(analysis.vna.actual_power.subtracted_amp(m_power, m_flux, m_gate,:), ...
                        analysis.vna.actual_power.subtracted_phase(m_power, m_flux, m_gate,:), ...
                        data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :), ...
                        input_params.q_circle_fit.gamma_int_guess, input_params.q_circle_fit.gamma_ext_guess, ...
                        input_params.q_circle_fit.sigma_guess);
                    
    analysis.vna.actual_power.fits_flucs_no_angle.goodness_fit(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_no_angle.fit_struct(input_params.run_number).goodness_fit;
    analysis.vna.actual_power.fits_flucs_no_angle.res_freq(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_no_angle.fit_struct(input_params.run_number).res_freq_fit;
    analysis.vna.actual_power.fits_flucs_no_angle.gamma_int(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_no_angle.fit_struct(input_params.run_number).gamma_int_fit;
    analysis.vna.actual_power.fits_flucs_no_angle.gamma_ext(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_no_angle.fit_struct(input_params.run_number).gamma_ext_fit;
    analysis.vna.actual_power.fits_flucs_no_angle.sigma(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_no_angle.fit_struct(input_params.run_number).sigma_fit;
    analysis.vna.actual_power.fits_flucs_no_angle.real(m_power, m_flux, m_gate, :) = analysis.vna.actual_power.fits_flucs_no_angle.fit_struct(input_params.run_number).theory_real;
    analysis.vna.actual_power.fits_flucs_no_angle.imag(m_power, m_flux, m_gate, :) = analysis.vna.actual_power.fits_flucs_no_angle.fit_struct(input_params.run_number).theory_imag;
                    
    [temp_lin_mag, temp_phase_radians] = extract_lin_mag_phase_from_real_imag( ...
            analysis.vna.actual_power.fits_flucs_no_angle.real(m_power, m_flux, m_gate, :), ...
            analysis.vna.actual_power.fits_flucs_no_angle.imag(m_power, m_flux, m_gate, :), ...
            data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :));
        
    [analysis.vna.actual_power.fits_flucs_no_angle.amp(m_power, m_flux, m_gate, :), ...
        analysis.vna.actual_power.fits_flucs_no_angle.phase(m_power, m_flux, m_gate, :)] = ...
        extract_log_mag_phase_degs(temp_lin_mag, temp_phase_radians);
    
    clear temp_lin_mag ...
          temp_phase_radians
                    
    [analysis.vna.actual_power.fits_flucs_and_angle.fit_struct(input_params.run_number)] = ...    
            fit_q_circle_with_freq_flucs_and_angle(analysis.vna.actual_power.subtracted_amp(m_power, m_flux, m_gate,:), ...
                        analysis.vna.actual_power.subtracted_phase(m_power, m_flux, m_gate,:), ...
                        data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :), ...
                        input_params.q_circle_fit.gamma_int_guess, input_params.q_circle_fit.gamma_ext_guess, ...
                        input_params.q_circle_fit.sigma_guess);
    
    analysis.vna.actual_power.fits_flucs_and_angle.goodness_fit(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_and_angle.fit_struct(input_params.run_number).goodness_fit;
    analysis.vna.actual_power.fits_flucs_and_angle.res_freq(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_and_angle.fit_struct(input_params.run_number).res_freq_fit;
    analysis.vna.actual_power.fits_flucs_and_angle.gamma_int(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_and_angle.fit_struct(input_params.run_number).gamma_int_fit;
    analysis.vna.actual_power.fits_flucs_and_angle.gamma_ext(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_and_angle.fit_struct(input_params.run_number).gamma_ext_fit;
    analysis.vna.actual_power.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_and_angle.fit_struct(input_params.run_number).sigma_fit;
    analysis.vna.actual_power.fits_flucs_and_angle.angle(m_power, m_flux, m_gate) = analysis.vna.actual_power.fits_flucs_and_angle.fit_struct(input_params.run_number).angle_fit;
    analysis.vna.actual_power.fits_flucs_and_angle.real(m_power, m_flux, m_gate, :) = analysis.vna.actual_power.fits_flucs_and_angle.fit_struct(input_params.run_number).theory_real;
    analysis.vna.actual_power.fits_flucs_and_angle.imag(m_power, m_flux, m_gate, :) = analysis.vna.actual_power.fits_flucs_and_angle.fit_struct(input_params.run_number).theory_imag;        

    [temp_lin_mag, temp_phase_radians] = extract_lin_mag_phase_from_real_imag( ...
            analysis.vna.actual_power.fits_flucs_and_angle.real(m_power, m_flux, m_gate, :), ...
            analysis.vna.actual_power.fits_flucs_and_angle.imag(m_power, m_flux, m_gate, :), ...
            data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :));
        
    [analysis.vna.actual_power.fits_flucs_and_angle.amp(m_power, m_flux, m_gate, :), ...
        analysis.vna.actual_power.fits_flucs_and_angle.phase(m_power, m_flux, m_gate, :)] = ...
        extract_log_mag_phase_degs(temp_lin_mag, temp_phase_radians); 
    
    clear temp_lin_mag ...
          temp_phase_radians
    %% Plot and save q-circle data at desired power
    if run_params.plot_visible == 1
        raw_amp_phase_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    elseif run_params.plot_visible == 0 
        raw_amp_phase_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
    end
    subplot(2, 1, 1)
    plot(gain_prof.freq, gain_prof.amp, 'DisplayName', 'gain profile')
    hold on
    plot(squeeze(data.vna.actual_power.rough.freq(m_power, m_flux, m_gate, :)), ...
            squeeze(data.vna.actual_power.rough.amp(m_power, m_flux, m_gate,:)), ...
            'DisplayName', 'rough')
    plot(squeeze(data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :)), ...
            squeeze(data.vna.actual_power.fine.amp(m_power, m_flux, m_gate,:)), ...
            'DisplayName', 'data')
    plot(squeeze(data.peripheral.expected_freq (m_power, m_bias_point)), min(squeeze(data.vna.actual_power.fine.amp(m_power, m_flux, m_gate,:))), ...
        'ko', 'markersize', 4, 'linewidth', 4)
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('$\vert S_{21} \vert$(dB)', 'interpreter', 'latex')
    title('gain profile log mag single photon drive')
    legend show
    subplot(2, 1, 2)
    plot(gain_prof.freq, gain_prof.phase, 'DisplayName', 'gain profile')
    hold on
    plot(squeeze(data.vna.actual_power.rough.freq(m_power, m_flux, m_gate, :)), ...
            squeeze(data.vna.actual_power.rough.phase(m_power, m_flux, m_gate,:)), ...
            'DisplayName', 'rough')
    plot(squeeze(data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :)), ...
            squeeze(data.vna.actual_power.fine.phase(m_power, m_flux, m_gate,:)), ...
            'DisplayName', 'data')    
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('Phase($S_{21})(^\circ)$', 'interpreter', 'latex')
    if run_params.save_data_and_png_param == 1
        save_file_name = [run_params.fig_directory num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) ...
            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_gain_prof_' num2str(run_params.vna.power) 'dBm.png'];
        saveas(raw_amp_phase_figure, save_file_name)
        save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) ...
            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_gain_prof_' num2str(run_params.vna.power) 'dBm.fig'];
        saveas(raw_amp_phase_figure, save_file_name)
    end
    clear raw_amp_phase_figure ...
          save_file_name
    
    if run_params.plot_visible == 1
        q_circle_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    elseif run_params.plot_visible == 0 
        q_circle_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
    end
    subplot(1, 3, 1)
    plot(squeeze(data.vna.actual_power.fine.real(m_power, m_flux, m_gate, :)), ...
            squeeze(data.vna.actual_power.fine.imag(m_power, m_flux, m_gate, :)), ...
            'o', 'markersize', 4, 'linewidth', 3, 'DisplayName', 'data')
    pbaspect([1 1 1 ])
    hold on
    plot(squeeze(analysis.vna.actual_power.fits_no_flucs.real(m_power, m_flux, m_gate, :)), ...
            squeeze(analysis.vna.actual_power.fits_no_flucs.imag(m_power, m_flux, m_gate, :)), ...
            'r', 'DisplayName', ['theory no flucs, error = ' ...
            num2str(analysis.vna.actual_power.fits_no_flucs.goodness_fit(m_power, m_flux, m_gate))])
    plot(squeeze(analysis.vna.actual_power.fits_flucs_no_angle.real(m_power, m_flux, m_gate, :)), ...
            squeeze(analysis.vna.actual_power.fits_flucs_no_angle.imag(m_power, m_flux, m_gate, :)), ...
            'b', 'DisplayName', ['theory, error = ' ...
            num2str(analysis.vna.actual_power.fits_flucs_no_angle.goodness_fit(m_power, m_flux, m_gate))])
    plot(squeeze(analysis.vna.actual_power.fits_flucs_and_angle.real(m_power, m_flux, m_gate, :)), ...
        squeeze(analysis.vna.actual_power.fits_flucs_and_angle.imag(m_power, m_flux, m_gate, :)), ...
        'k', 'DisplayName', ['theory with angle, error = ' ...
        num2str(analysis.vna.actual_power.fits_flucs_and_angle.goodness_fit(m_power, m_flux, m_gate))])
    xlabel('$\Gamma_{\mathrm{real}}$', 'interpreter', 'latex')
    ylabel('$\Gamma_{\mathrm{imag}}$', 'interpreter', 'latex')
    sgtitle(['resonance circles @ -65dBm for $n_g$ = ' num2str(run_params.ng_1_value) 'elns, flux = ' num2str(run_params.flux_1_value) ...
        '$\phi_0$.' 13 10 ' no flucs : $\omega_0$ = ' ...
        num2str(analysis.vna.actual_power.fits_no_flucs.res_freq(m_power, m_flux, m_gate)/1e9) ...
        'GHz, $\kappa_{\mathrm{int}}$ = ' ...
        num2str(analysis.vna.actual_power.fits_no_flucs.gamma_int(m_power, m_flux, m_gate)/1e6) ...
        'MHz, $\kappa_{\mathrm{ext}}$ = ' ...
        num2str(analysis.vna.actual_power.fits_no_flucs.gamma_ext(m_power, m_flux, m_gate)/1e6) ...
        'MHz' 13 10 ' flucs no angle : $\omega_0$ = ' ...
        num2str(analysis.vna.actual_power.fits_flucs_no_angle.res_freq(m_power, m_flux, m_gate)/1e9) ...
        'GHz, $\kappa_{\mathrm{ext}}$ = ' ...
        num2str(analysis.vna.actual_power.fits_flucs_no_angle.gamma_ext(m_power, m_flux, m_gate)/1e6) ...
        'MHz, $\kappa_{\mathrm{int}}$ = ' ...
        num2str(analysis.vna.actual_power.fits_flucs_no_angle.gamma_int(m_power, m_flux, m_gate)/1e6) ...
        'MHz, $\sigma_{\omega_0}$ = ' ...
        num2str(analysis.vna.actual_power.fits_flucs_no_angle.sigma(m_power, m_flux, m_gate)/1e6) ...
        'MHz.' 13 10 'flucs with angle : $\omega_0$ = ' ...
        num2str(analysis.vna.actual_power.fits_flucs_and_angle.res_freq(m_power, m_flux, m_gate)/1e9) ...
        'GHz, $\kappa_{\mathrm{ext}}$ = ' ...
        num2str(analysis.vna.actual_power.fits_flucs_and_angle.gamma_ext(m_power, m_flux, m_gate)/1e6) ...
        'MHz, $\kappa_{\mathrm{int}}$ = ' ...
        num2str(analysis.vna.actual_power.fits_flucs_and_angle.gamma_int(m_power, m_flux, m_gate)/1e6) ...
        'MHz, $\sigma_{\omega_0}$ = ' ...
        num2str(analysis.vna.actual_power.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)/1e6) ...
        'MHz, angle = ' ...
        num2str(analysis.vna.actual_power.fits_flucs_and_angle.angle(m_power, m_flux, m_gate)/1e6) ...
        '$^\circ$'], 'interpreter', 'latex');
    
    subplot(1, 3, 2)
    plot(squeeze(data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.actual_power.subtracted_amp(m_power, m_flux, m_gate,:)), ...
            'o', 'markersize', 4, 'linewidth', 3, 'DisplayName', 'data')
    hold on
    plot(squeeze(data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.actual_power.fits_no_flucs.amp(m_power, m_flux, m_gate,:)), ...
            'r', 'DisplayName', ['theory no flucs, error = ' ...
            num2str(analysis.vna.actual_power.fits_no_flucs.goodness_fit(m_power, m_flux, m_gate))])
    plot(squeeze(data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.actual_power.fits_flucs_no_angle.amp(m_power, m_flux, m_gate,:)), ...
            'b', 'DisplayName', ['theory with flucs, error = ' ...
            num2str(analysis.vna.actual_power.fits_flucs_no_angle.goodness_fit(m_power, m_flux, m_gate))])  
    plot(squeeze(data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.actual_power.fits_flucs_and_angle.amp(m_power, m_flux, m_gate,:)), ...
            'k', 'DisplayName', ['theory with flucs and angle, error = ' ...
            num2str(analysis.vna.actual_power.fits_flucs_and_angle.goodness_fit(m_power, m_flux, m_gate))])        
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('$\vert S_{21} \vert $(dB)', 'interpreter', 'latex')
    legend show
    
     subplot(1, 3, 3)
    plot(squeeze(data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.actual_power.subtracted_phase(m_power, m_flux, m_gate,:)), ...
            'o', 'markersize', 4, 'linewidth', 3, 'DisplayName', 'data')
    hold on
    plot(squeeze(data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.actual_power.fits_no_flucs.phase(m_power, m_flux, m_gate,:)), ...
            'r', 'DisplayName', ['theory no flucs, error = ' ...
            num2str(analysis.vna.actual_power.fits_no_flucs.goodness_fit(m_power, m_flux, m_gate))])
    plot(squeeze(data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.actual_power.fits_flucs_no_angle.phase(m_power, m_flux, m_gate,:)), ...
            'b', 'DisplayName', ['theory with flucs, error = ' ...
            num2str(analysis.vna.actual_power.fits_flucs_no_angle.goodness_fit(m_power, m_flux, m_gate))])  
    plot(squeeze(data.vna.actual_power.fine.freq(m_power, m_flux, m_gate, :))/1e9, ...
            squeeze(analysis.vna.actual_power.fits_flucs_and_angle.phase(m_power, m_flux, m_gate,:)), ...
            'k', 'DisplayName', ['theory with flucs and angle, error = ' ...
            num2str(analysis.vna.actual_power.fits_flucs_and_angle.goodness_fit(m_power, m_flux, m_gate))])        
    xlabel('Freq (GHz)', 'interpreter', 'latex')
    ylabel('$Phase(S_{21}$) $(^\circ)$', 'interpreter', 'latex')
    
    if run_params.save_data_and_png_param == 1
        save_file_name = [run_params.fig_directory num2str(m_power) '_' num2str(m_bias_point) ...
            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_q_fit_' num2str(run_params.vna.power) 'dBm.png'];
        saveas(q_circle_figure, save_file_name)
        save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_power) '_' num2str(m_bias_point) ...
            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_q_fit_' num2str(run_params.vna.power) 'dBm.fig'];
        saveas(q_circle_figure, save_file_name)
    end
    close all
    clear q_circle_figure ...
          save_file_name
else
    disp('skipping desired power VNA capture')
end
%% generate AWG waveform and sequence and send to AWG
if run_params.awg.files_generation_param == 1
    disp('generating awg waveforms and sequences')
    %%%%%% generate a do nothing pulse 1us long and send to AWG
    file_list = awg_list_files(awg);
    if contains(file_list, 'do_nothing_1us.wfm')
        awg_delete_file(awg, 'do_nothing_1us.wfm')
    end
    [do_nothing_time, do_nothing_waveform, do_nothing_marker] = ...
            generate_steady_on_with_defined_markers(input_params.awg.clock, input_params.awg.input_IF_waveform_freq, ...
                    -1000, 1, 0); %%% -1000 is the amplitude for this code, and that value generates a 0 amp waveform
    [~] = send_waveform_awg520(awg,do_nothing_time,do_nothing_waveform,do_nothing_marker,'do_nothing_1us.wfm');    
    clear do_nothing_time ...
          do_nothing_waveform ...
          do_nothing_marker
    %%%% generate stabilization time waveform, where the marker is at 0,
    %%%% doesn't trigger
    if contains(file_list, [num2str(run_params.awg.output_power) 'dBm_1us_steady_marker_off.wfm'])
        awg_delete_file(awg, [num2str(run_params.awg.output_power) 'dBm_1us_steady_marker_off.wfm'])
    end
    [stabilization_time_axis, stabilization_waveform, stabilization_marker] = ...
            generate_steady_on_with_defined_markers(input_params.awg.clock, input_params.awg.input_IF_waveform_freq, ...
                    run_params.awg.output_power, 1, 0);
    [~] = send_waveform_awg520(awg, stabilization_time_axis, stabilization_waveform, stabilization_marker, ...
            [num2str(run_params.awg.output_power) 'dBm_1us_steady_marker_off.wfm']);
    clear stabilization_time_axis ...
          stabilization_waveform ...
          stabilization_marker
    %%%% generate stabilization time waveform, where the marker is at 0,
    %%%% triggers
    if contains(file_list, [num2str(run_params.awg.output_power) 'dBm_10us_steady_marker_on.wfm'])
        awg_delete_file(awg, [num2str(run_params.awg.output_power) 'dBm_10us_steady_marker_on.wfm'])
    end
    [steady_on_time_axis, steady_on_waveform, steady_on_marker] = ...
            generate_steady_on_with_defined_markers(input_params.awg.clock, input_params.awg.input_IF_waveform_freq, ...
                    run_params.awg.output_power, 10, 1);
    [~] = send_waveform_awg520(awg, steady_on_time_axis, steady_on_waveform, steady_on_marker, ...
            [num2str(run_params.awg.output_power) 'dBm_10us_steady_marker_on.wfm']);
    clear steady_on_time_axis ...
          steady_on_waveform ...
          steady_on_marker


    if contains(file_list, run_params.awg.sequence)
        awg_delete_file(awg, run_params.awg.sequence)
    end
    number_to_repeat_do_nothing_waveform = input_params.awg.continuous_amplitude_down_time * 1e6;
    number_to_repeat_stabilization_waveform = input_params.awg.stabilization_buffer_time * 1e6;
    number_to_repeat_steady_on_waveform = ceil(input_params.digitizer.data_collection_time/10e-6);
    sequence_repeat_array = [number_to_repeat_do_nothing_waveform; number_to_repeat_stabilization_waveform; number_to_repeat_steady_on_waveform; number_to_repeat_do_nothing_waveform];
    waveform_file_array{1,1} = 'do_nothing_1us.wfm';
    waveform_file_array{1,2} = [num2str(run_params.awg.output_power) 'dBm_1us_steady_marker_off.wfm'];
    waveform_file_array{1,3} = [num2str(run_params.awg.output_power) 'dBm_10us_steady_marker_on.wfm'];
    waveform_file_array{1,4} = 'do_nothing_1us.wfm';
    awg_send_sequence(awg, 4, 1, waveform_file_array, sequence_repeat_array, run_params.awg.sequence(1:end-4), 1);
    clear number_to_repeat_do_nothing_waveform ...
          number_to_repeat_stabilization_waveform ...
          number_to_repeat_steady_on_waveform ...
          sequence_repeat_array waveform_file_array ...
          file_list
end
%% set sig gen params
disp('setting sig gens. Not AWG.')
input_params.center_freq(m_power, m_flux, m_gate, m_detuning, m_repetition) = res_freq + detuning_point*1e6;
input_params.sig_gen.input_LO_power(m_power, m_flux, m_gate, m_detuning, m_repetition) = 17; % input power to IQ4509 input mixer is 15dBm
input_params.sig_gen.input_LO_freq (m_power, m_flux, m_gate, m_detuning, m_repetition) = input_params.center_freq(m_power, m_flux, m_gate, m_detuning, m_repetition) - ...
    input_params.awg.input_IF_waveform_freq;
n5183b_set_frequency(keysight_sg, squeeze(input_params.sig_gen.input_LO_freq (m_power, m_flux, m_gate, m_detuning, m_repetition)))
n5183b_set_amplitude(keysight_sg, squeeze(input_params.sig_gen.input_LO_power(m_power, m_flux, m_gate, m_detuning, m_repetition)))
% the IF to IQ4509 is at 84MHz, defined in the above AWG waveforms
input_params.sig_gen.output_LO_power(m_power, m_flux, m_gate, m_detuning,  m_repetition) = 16.8; % input power to mini circuits ZXF05 - 73L+ output mixer is 15dBm
input_params.sig_gen.output_LO_freq (m_power, m_flux, m_gate, m_detuning,  m_repetition) = input_params.center_freq(m_power, m_flux, m_gate, m_detuning,  m_repetition) + ...
    input_params.if_freq;
e8257c_set_frequency(e8257c_sig_gen, squeeze(input_params.sig_gen.output_LO_freq (m_power, m_flux, m_gate, m_detuning,  m_repetition)))
e8257c_set_amplitude(e8257c_sig_gen, squeeze(input_params.sig_gen.output_LO_power(m_power, m_flux, m_gate, m_detuning,  m_repetition)))
%% switch to phase line on switches
switch_phase_measurement
%% setup AWG
if run_params.awg.files_generation_param == 1 || m_detuning == run_params.detuning_point_start
    disp('setting AWG')
    awg_load_waveform(awg, 1, run_params.awg.sequence)
    awg_set_ref_source(awg, 'ext')
    awg_set_run_mode(awg, 'cont')
    awg_toggle_output(awg, 'on', 1)
    awg_set_trig_source(awg, 'ext')
    awg_run_output_channel_off(awg, 'run')
end
%% turn on sig gens
disp('sig gens now on')
n5183b_toggle_output(keysight_sg, 'on')
e8257c_toggle_output(e8257c_sig_gen, 'on')
%% Data acquisition
% Call mfile with library definitions
AlazarDefs
disp('collecting phase vs time data')
% Load driver library
if ~alazarLoadLibrary()
  fprintf('Error: ATSApi library not loaded\n');
  return
end

systemId = int32(1);
boardId = int32(1);

% Get a handle to the board
boardHandle = AlazarGetBoardBySystemID(systemId, boardId);
setdatatype(boardHandle, 'voidPtr', 1, 1);
if boardHandle.Value == 0
  fprintf('Error: Unable to open board system ID %u board ID %u\n', systemId, boardId);
  return
end
if m_bias_point == 1
    [result] = configureBoard(boardHandle, input_params.digitizer.sample_rate, ...
        input_params.digitizer.trigger_level, convert_dBm_to_Vp(run_params.input_power_value + input_params.fridge_attenuation));
        % expect ~ 0dB gain from fridge. so the power going to fridge is probably commensurate with the power at insert top
    if ~result
      fprintf('Error: Board configuration failed\n');
      return
    end
end
clear result

% Acquire data, optionally saving it to a file
[ret_code, raw_data.time, raw_data.voltage] = acquireData(boardHandle, input_params.digitizer.sample_rate, input_params.digitizer.data_collection_time, ...
    1, convert_dBm_to_Vp(run_params.input_power_value + input_params.fridge_attenuation));
if ~ret_code
    fprintf('Error: Acquisition failed\n');
end
clear ret_code
disp('acquired raw data')
%% Reshape data for analysis
disp('reshaping raw data')
%%%% get rid of unfilled buffers - since they have all elements 0
%%%% each buffer is in dimension 1, time and amp points of that buffer in dimension 2
amp_row_mean = mean(raw_data.voltage, 2);
mean_matrix = repmat(amp_row_mean, 1, size(raw_data.voltage,2));
raw_data.voltage(mean_matrix == 0) = [];
raw_data.voltage = reshape(raw_data.voltage, [], size(raw_data.time, 2));
raw_data.time(mean_matrix == 0) = [];
raw_data.time = reshape(raw_data.time, [], size(raw_data.voltage, 2));
clear mean_matrix amp_row_mean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% get rid of CH B data (just noise, but collected to avoid digitizer hanging up 
raw_data.time = raw_data.time(:, 1:size(raw_data.time,2)/2);
raw_data.voltage = raw_data.voltage(:, 1:size(raw_data.voltage,2)/2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% resize to a vector to feed into the digital heterodyning code
size_required = size(raw_data.time');
raw_data.time = reshape(raw_data.time', [], 1);
raw_data.voltage = reshape(raw_data.voltage', [], 1);
%%%%%%%%%%%%%%%%%%%%
%%% reshape the transpose, since the reshape in next step (and always) goes down
%%% column first and this way those are the time points that need to stay together
if ~run_params.analysis_during_acquisition
    if run_params.save_data_and_png_param == 1
        if ~exist('m_save_data_counter', 'var')
            disp('doesnt exist')
            m_save_data_counter = 1;
            m_record = 1;
        end
    end
end

%%%%% extract amp and phase if performing analysis and reshape to original array dimensions %%%%%%
% if run_params.analysis_during_acquisition 
[raw_data.amp_extracted, raw_data.phase_extracted] = get_amp_and_phase(raw_data.time, raw_data.voltage, input_params.if_freq, input_params.digitizer.sample_rate);
raw_data.amp_extracted = reshape(raw_data.amp_extracted', size_required)';
raw_data.phase_extracted = 180/pi*reshape(raw_data.phase_extracted', size_required)';
raw_data.time = reshape(raw_data.time', size_required)';
raw_data.voltage = reshape(raw_data.voltage', size_required)';
%% turn off sig gens (not AWG unless the last detuning point)
disp('sig gens are off. AWG still on')
n5183b_toggle_output(keysight_sg, 'off')
e8257c_toggle_output(e8257c_sig_gen,'off')
n5183b_toggle_pulse_mod(keysight_sg,'off')
n5183b_toggle_modulation(keysight_sg,'off')

if (detuning_point > run_params.detuning_point_end + run_params.detuning_point_step || detuning_point == run_params.detuning_point_end) && ...
            m_repetition == input_params.number_repetitions    
        disp('sig gens off, AWG also off')
        awg_toggle_output(awg,'off',1)
        awg_toggle_output(awg,'off',2)
        awg_run_output_channel_off(awg,'stop')
end
%% save only raw data matrix struct for further analysis later 
if run_params.save_data_and_png_param == 1 && ~run_params.analysis_during_acquisition
        %     raw_data_matrix.time(m_save_data_counter, :) = raw_data.time;
    raw_data_matrix.voltage(m_save_data_counter, :, :) = raw_data.voltage;
    raw_data_matrix.detuning_point_number(m_save_data_counter) = m_detuning;
    raw_data_matrix.detuning_point(m_save_data_counter) = detuning_point;
    raw_data_matrix.repetition_number(m_save_data_counter) = m_repetition;
    raw_data_matrix.input_power_number(m_save_data_counter) = m_power;
    raw_data_matrix.ng_number(m_save_data_counter) = m_gate;
    raw_data_matrix.flux_number(m_save_data_counter) = m_flux;
    raw_data_matrix.bias_point_number(m_save_data_counter) = m_bias_point;
    %     raw_data_matrix.amp_extracted(m_save_data_counter, :) = raw_data.amp_extracted;
    %     raw_data_matrix.phase_extracted(m_save_data_counter, :) = raw_data.phase_extracted;

    if m_save_data_counter == input_params.save_raw_data_frequency ||((detuning_point > run_params.detuning_point_end + run_params.detuning_point_step ...
            || detuning_point == run_params.detuning_point_end) && m_repetition == input_params.number_repetitions)    
        save([run_params.data_directory '\' num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) '_' ...
            'raw_data_record_' num2str(m_record) '.mat'], 'raw_data_matrix')   
        m_save_data_counter = 0;
        clear raw_data_matrix
        disp('saved raw data')
        m_record = m_record + 1;
    end
    clear raw_data ...
          size_required
    m_save_data_counter = m_save_data_counter + 1;
end
%% clear some unrequired variables that will be reloaded next iteration of this function
clear vna_data_acquisition ...
      res_freq_recorder ...
      bias_set_param 
clear_alazar_board_variables
clear_instruments
%% waveform generation function
function [time_axis, waveform_data, marker_data] = ...
    generate_steady_on_with_defined_markers(awg_clock,IF_waveform_freq, amplitude_in_dBm, waveform_time_us, marker_2_value, phase)

    % amplitude of -1000 dBm generates a waveform with all zeros (do nothing pulse)
    % awg_clock is AWG sampling rate in S/s
    % all times in us.
    % sin wave generated at 84MHz
    % waveofrm_time_us is the length of sin wave generated
    % phase in degs
    % outputs a time series, desired waveform and the appropriate markers -
    % marker 1 - irrelevant, all 0s.
    % marker 2 - data acquisition trigger - specified by marker_2_value to be 0 or 1 throughout waveform
    if ~exist('phase','var')
        phase = 0;
    end
    
    if mod(awg_clock, IF_waveform_freq) ~= 0
        disp('IF waveform for input IQ4509 mixer needs to be fixed')
    end
    
    if mod(waveform_time_us, 1) ~= 0
        disp('recording time must be a whole number in us')
        return
    end 
    if mod(awg_clock/1e6, 1) ~= 0
        disp('AWG needs to be a whole number in MS/s')
        return
    end
    
    amplitude_Vp = 2*convert_dBm_to_Vp(amplitude_in_dBm); % 2* because of idiosyncracy of AWG output channel - 1Vpp, not 2Vpp

    if amplitude_Vp < 0.01 && amplitude_in_dBm ~= -1000
        disp('AWG cannot output desired voltage accurately')
        return
    elseif amplitude_in_dBm == -1000
        amplitude_Vp = 0;
    end
    
    waveform_time = waveform_time_us* 1e-6;
    
    time_axis = 0 : 1/awg_clock : waveform_time - 1/awg_clock;

    if abs((awg_clock/1e6)*((time_axis(end)+ 1/awg_clock)*1e6 ) - floor((awg_clock/1e6)*((time_axis(end) + 1/awg_clock)*1e6 ))) > 1/awg_clock/10 && ...
        abs((awg_clock/1e6)*((time_axis(end)+ 1/awg_clock)*1e6 ) - ceil((awg_clock/1e6)*((time_axis(end) + 1/awg_clock)*1e6 ))) > 1/awg_clock/10  
        disp('check pulse length and clock freq')
        return
    end
    
    if abs(max(diff(time_axis) - mean(diff(time_axis)))) > 1e-19
        disp('time prob')
        return
    end
    
    waveform_data = amplitude_Vp*sin(2*pi*IF_waveform_freq*(time_axis) + phase*pi/180);
    marker_data = zeros(2, length(time_axis));
    marker_data(2, :) = marker_2_value;
end
%% %% AlazarTech configure board function %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [result] = configureBoard(boardHandle, sample_rate, trigger_level, input_level)
% Configure sample rate, input, and trigger settings

% Call mfile with library definitions
AlazarDefs

if ~exist('trigger_level','var')
    trigger_level = 225;
end

% set default return code to indicate failure
result = false;

% TODO: Select clock parameters as required to generate this sample rate.
%
% For example: if samplesPerSec is 100.e6 (100 MS/s), then:
% - select clock source INTERNAL_CLOCK and sample rate SAMPLE_RATE_100MSPS
% - select clock source FAST_EXTERNAL_CLOCK, sample rate SAMPLE_RATE_USER_DEF,
%   and connect a 100 MHz signalto the EXT CLK BNC connector.

% global variable used in acquireData.m


retCode = ...
    AlazarSetCaptureClock(  ...
        boardHandle,        ... % HANDLE -- board handle
        FAST_EXTERNAL_CLOCK,     ... % U32 -- clock source id
        sample_rate, ... % U32 -- sample rate id
        CLOCK_EDGE_RISING,  ... % U32 -- clock edge id
        0                   ... % U32 -- clock decimation
        );
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetCaptureClock failed -- %s\n', errorToText(retCode));
    return
end
% TODO: Select channel A input parameters as required.

if input_level <= .19
    input_range = INPUT_RANGE_PM_200_MV;
elseif input_level > .19 && input_level <= .39
    input_range = INPUT_RANGE_PM_400_MV;
elseif input_level > .39 && input_level <= .79
    input_range = INPUT_RANGE_PM_800_MV;
elseif input_level > .79 && input_level <=2
    input_range = INPUT_RANGE_PM_2_V;
else
    disp('input level too high')
    return
end

retCode = ...
    AlazarInputControlEx(             ...
        boardHandle,                  ... % HANDLE -- board handle
        CHANNEL_A,     ... % U32 -- input channel
        DC_COUPLING,    ... % U32 -- input coupling id
        input_range, ... % U32 -- input range id
        IMPEDANCE_50_OHM    ... % U32 -- input impedance id
        );
if retCode ~= ApiSuccess
    fprintf('Error: AlazarInputControlEx failed -- %s\n', errorToText(retCode));
    return
end
% TODO: Select channel A bandwidth limit as required
retCode = ...
    AlazarSetBWLimit( ...
        boardHandle,  ... % HANDLE -- board handle
        CHANNEL_A, ... % U8 -- channel identifier
        0             ... % U32 -- 0 = disable, 1 = enable
        );
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetBWLimit failed -- %s\n', errorToText(retCode));
    return
end
% TODO: Select channel B input parameters as required.
retCode = ...
    AlazarInputControlEx(             ...
        boardHandle,                  ... % HANDLE -- board handle
        CHANNEL_B,     ... % U32 -- input channel
        DC_COUPLING,    ... % U32 -- input coupling id
        INPUT_RANGE_PM_400_MV, ... % U32 -- input range id
        IMPEDANCE_50_OHM    ... % U32 -- input impedance id
        );
if retCode ~= ApiSuccess
    fprintf('Error: AlazarInputControlEx failed -- %s\n', errorToText(retCode));
    return
end
% TODO: Select channel B bandwidth limit as required
retCode = ...
    AlazarSetBWLimit( ...
        boardHandle,  ... % HANDLE -- board handle
        CHANNEL_B, ... % U8 -- channel identifier
        0             ... % U32 -- 0 = disable, 1 = enable
        );
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetBWLimit failed -- %s\n', errorToText(retCode));
    return
end

% TODO: Select trigger inputs and levels as required
retCode = ...
    AlazarSetTriggerOperation( ...
        boardHandle,        ... % HANDLE -- board handle
        TRIG_ENGINE_OP_J,   ... % U32 -- trigger operation
        TRIG_ENGINE_J,      ... % U32 -- trigger engine id
        TRIG_EXTERNAL,        ... % U32 -- trigger source id
        TRIGGER_SLOPE_POSITIVE, ... % U32 -- trigger slope id
        trigger_level,                ... % U32 -- trigger level from 0 (-range) to 255 (+range)   %225 is ~0.75V for 2Vpp trigger such as marker from AWG
        TRIG_ENGINE_K,      ... % U32 -- trigger engine id
        TRIG_DISABLE,       ... % U32 -- trigger source id for engine K
        TRIGGER_SLOPE_POSITIVE, ... % U32 -- trigger slope id
        128                 ... % U32 -- trigger level from 0 (-range) to 255 (+range)
        );
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetTriggerOperation failed -- %s\n', errorToText(retCode));
    return
end

% TODO: Select external trigger parameters as required
retCode = ...
    AlazarSetExternalTrigger( ...
        boardHandle,        ... % HANDLE -- board handle
        DC_COUPLING,        ... % U32 -- external trigger coupling id
        ETR_1V              ... % U32 -- external trigger range id  %  1V for marker from AWG
        );
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetExternalTrigger failed -- %s\n', errorToText(retCode));
    return
end

% TODO: Set trigger delay as required.
triggerDelay_sec = 0;
triggerDelay_samples = uint32(floor(triggerDelay_sec * sample_rate + 0.5));
retCode = AlazarSetTriggerDelay(boardHandle, triggerDelay_samples);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetTriggerDelay failed -- %s\n', errorToText(retCode));
    return;
end

% TODO: Set trigger timeout as required.

% NOTE:
% The board will wait for a for this amount of time for a trigger event.
% If a trigger event does not arrive, then the board will automatically
% trigger. Set the trigger timeout value to 0 to force the board to wait
% forever for a trigger event.
%
% IMPORTANT:
% The trigger timeout value should be set to zero after appropriate
% trigger parameters have been determined, otherwise the
% board may trigger if the timeout interval expires before a
% hardware trigger event arrives.
triggerTimeout_sec = 0;
triggerTimeout_clocks = uint32(floor(triggerTimeout_sec / 10.e-6 + 0.5));
retCode = ...
    AlazarSetTriggerTimeOut(    ...
        boardHandle,            ... % HANDLE -- board handle
        triggerTimeout_clocks   ... % U32 -- timeout_sec / 10.e-6 (0 == wait forever)
        );
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetTriggerTimeOut failed -- %s\n', errorToText(retCode));
    return
end

% TODO: Configure AUX I/O connector as required
retCode = ...
    AlazarConfigureAuxIO(   ...
        boardHandle,        ... % HANDLE -- board handle
        AUX_OUT_TRIGGER,    ... % U32 -- mode
        0                   ... % U32 -- parameter
        );
if retCode ~= ApiSuccess
    fprintf('Error: AlazarConfigureAuxIO failed -- %s\n', errorToText(retCode));
    return
end

% set return code to indicate success
result = true;
end

%% AlazarTech acquire data function %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [result, time_out, data_out] = acquireData(boardHandle, sample_rate, acquisition_length_per_trigger, averaging_number_per_waveform, input_level)
% Make an AutoDMA acquisition from dual-ported memory.

% set default return code to indicate failure
result = false;

% call mfile with library definitions
AlazarDefs
% There are no pre-trigger samples in NPT mode
preTriggerSamples = 0;

% TODO: Select the number of post-trigger samples per record
% postTriggerSamples = 2048;
postTriggerSamples = acquisition_length_per_trigger * sample_rate;
mod_post_trigger_length = mod(postTriggerSamples, 32);
if mod_post_trigger_length ~=0
    postTriggerSamples = postTriggerSamples + 32 - mod_post_trigger_length;
end

% TODO: Specify the number of records per channel per DMA buffer
recordsPerBuffer = 1;

% TODO: Specifiy the total number of buffers to capture
% buffersPerAcquisition = 10;
buffersPerAcquisition = averaging_number_per_waveform; 


% TODO: Select which channels to capture (A, B, or both)
channelMask = CHANNEL_A + CHANNEL_B;

% TODO: Select if you wish to save the sample data to a binary file
saveData = false;

% TODO: Select if you wish to plot the data to a chart
drawData = false;

if input_level <= .19
    input_range = .2;
elseif input_level > .19 && input_level <= .39
    input_range = .4;
elseif input_level > .39 && input_level <= .79
    input_range = .8;
elseif input_level > .79 && input_level <=2
    input_range = 2;
else
    disp('input level too high')
    return
end
disp(['Digitizer input level set at ' num2str(input_range) 'V'])
% Calculate the number of enabled channels from the channel mask
channelCount = 0;
channelsPerBoard = 2;
for channel = 0:channelsPerBoard - 1
    channelId = 2^channel;
    if bitand(channelId, channelMask)
        channelCount = channelCount + 1;
    end
end

if (channelCount < 1) || (channelCount > channelsPerBoard)
    fprintf('Error: Invalid channel mask %08X\n', channelMask);
    return
end

% Get the sample and memory size
[retCode, boardHandle, ~, bitsPerSample] = AlazarGetChannelInfo(boardHandle, 0, 0); %%% [retCode, boardHandle, maxSamplesPerRecord, bitsPerSample]
if retCode ~= ApiSuccess
    fprintf('Error: AlazarGetChannelInfo failed -- %s\n', errorToText(retCode));
    return
end

% Calculate the size of each buffer in bytes
bytesPerSample = floor((double(bitsPerSample) + 7) / double(8));
samplesPerRecord = preTriggerSamples + postTriggerSamples;
samplesPerBuffer = samplesPerRecord * recordsPerBuffer * channelCount;
bytesPerBuffer = bytesPerSample * samplesPerBuffer;

% TODO: Select the number of DMA buffers to allocate.
% The number of DMA buffers must be greater than 2 to allow a board to DMA into
% one buffer while, at the same time, your application processes another buffer.
bufferCount = uint32(20);

% averaging_number_per_waveform
% samplesPerBuffer
time_out = zeros(averaging_number_per_waveform, samplesPerBuffer);
data_out = time_out;

% Create an array of DMA buffers
buffers = cell(1, bufferCount);
for j = 1 : bufferCount
    pbuffer = AlazarAllocBuffer(boardHandle, bytesPerBuffer);
    if pbuffer == 0
        fprintf('Error: AlazarAllocBuffer %u samples failed\n', samplesPerBuffer);
        return
    end
    buffers(1, j) = { pbuffer };
end

% Create a data file if required
fid = -1;
if saveData
    fid = fopen('data.bin', 'w');
    if fid == -1
        fprintf('Error: Unable to create data file\n');
    end
end
% Set the record size
retCode = AlazarSetRecordSize(boardHandle, preTriggerSamples, postTriggerSamples);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetRecordSize failed -- %s\n', errorToText(retCode));
    return
end

% TODO: Select AutoDMA flags as required
admaFlags = ADMA_EXTERNAL_STARTCAPTURE + ADMA_NPT;

% Configure the board to make an AutoDMA acquisition
recordsPerAcquisition = recordsPerBuffer * buffersPerAcquisition;
retCode = AlazarBeforeAsyncRead(boardHandle, channelMask, -int32(preTriggerSamples), samplesPerRecord, recordsPerBuffer, recordsPerAcquisition, admaFlags);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarBeforeAsyncRead failed -- %s\n', errorToText(retCode));
    return
end

% Post the buffers to the board
for bufferIndex = 1 : bufferCount
    pbuffer = buffers{1, bufferIndex};
    retCode = AlazarPostAsyncBuffer(boardHandle, pbuffer, bytesPerBuffer);
    if retCode ~= ApiSuccess
        fprintf('Error: AlazarPostAsyncBuffer failed -- %s\n', errorToText(retCode));
        return
    end
end

% Update status
if buffersPerAcquisition == hex2dec('7FFFFFFF')
    fprintf('Capturing buffers until aborted...\n');
else
    fprintf('Capturing %u buffers ...\n', buffersPerAcquisition);
end

% Arm the board system to wait for triggers
retCode = AlazarStartCapture(boardHandle);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarStartCapture failed -- %s\n', errorToText(retCode));
    return
end

% Create a progress window
waitbarHandle = waitbar(0, ...
                        'Captured 0 buffers', ...
                        'Name','Capturing ...', ...
                        'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
setappdata(waitbarHandle, 'canceling', 0);

% Wait for sufficient data to arrive to fill a buffer, process the buffer,
% and repeat until the acquisition is complete
startTickCount = tic;
updateTickCount = tic;
updateInterval_sec = 0.1;
buffersCompleted = 0;
captureDone = false;
success = false;

% awg_trigger(awg_handle)

while ~captureDone

    bufferIndex = mod(buffersCompleted, bufferCount) + 1;
    pbuffer = buffers{1, bufferIndex};

    % Wait for the first available buffer to be filled by the board
    [retCode, boardHandle, bufferOut] = ...
        AlazarWaitAsyncBufferComplete(boardHandle, pbuffer, 5000);
    if retCode == ApiSuccess
        % This buffer is full
        bufferFull = true;
        captureDone = false;
    elseif retCode == ApiWaitTimeout
        % The wait timeout expired before this buffer was filled.
        % The board may not be triggering, or the timeout period may be too short.
        fprintf('Error: AlazarWaitAsyncBufferComplete timeout -- Verify trigger!\n');
        bufferFull = false;
        captureDone = true;
    else
        % The acquisition failed
        fprintf('Error: AlazarWaitAsyncBufferComplete failed -- %s\n', errorToText(retCode));
        bufferFull = false;
        captureDone = true;
    end

    if bufferFull
        % TODO: Process sample data in this buffer.
        %
        % NOTE:
        %
        % While you are processing this buffer, the board is already
        % filling the next available buffer(s).
        %
        % You MUST finish processing this buffer and post it back to the
        % board before the board fills all of its available DMA buffers
        % and on-board memory.
        %
        % Records are arranged in the buffer as follows: R0A, R1A, R2A ... RnA, R0B,
        % R1B, R2B ...
        % with RXY the record number X of channel Y
        %
        %
        % Sample codes are unsigned by default. As a result:
        % - a sample code of 0x0000 represents a negative full scale input signal.
        % - a sample code of 0x8000 represents a ~0V signal.
        % - a sample code of 0xFFFF represents a positive full scale input signal.

        if bytesPerSample == 1
            setdatatype(bufferOut, 'uint8Ptr', 1, samplesPerBuffer);
        else
            setdatatype(bufferOut, 'uint16Ptr', 1, samplesPerBuffer);
        end

        % Save the buffer to file
        if fid ~= -1
            if bytesPerSample == 1
                samplesWritten = fwrite(fid, bufferOut.Value, 'uint8');
            else
                samplesWritten = fwrite(fid, bufferOut.Value, 'uint16');
            end
            if samplesWritten ~= samplesPerBuffer
                fprintf('Error: Write buffer %u failed\n', buffersCompleted);
            end
        end

        % Display the buffer on screen
        if drawData
            data_out_adc = double(bufferOut.Value);
            conversion_slope=.2/(65535-32768);
            data_temp=conversion_slope.*(data_out_adc-32768);
            size(data_temp)
        end
        time=0:1/sample_rate:length(bufferOut.Value)/sample_rate-1/sample_rate;
        test_out_adc=double(bufferOut.Value);
        slope=(input_range-0)/(65535-32768);       %INPUT_RANGE_PM_200_mV
        data = slope.*(test_out_adc-32768);
        time_out(buffersCompleted + 1, :) = time;
        data_out(buffersCompleted + 1, :) = data;

        % Make the buffer available to be filled again by the board
        retCode = AlazarPostAsyncBuffer(boardHandle, pbuffer, bytesPerBuffer);
        if retCode ~= ApiSuccess
            fprintf('Error: AlazarPostAsyncBuffer failed -- %s\n', errorToText(retCode));
            captureDone = true;
        end

        % Update progress
        buffersCompleted = buffersCompleted + 1;
        if buffersCompleted >= buffersPerAcquisition
            captureDone = true;
            success = true;
        elseif toc(updateTickCount) > updateInterval_sec
            updateTickCount = tic;

            % Update waitbar progress
            waitbar(double(buffersCompleted) / double(buffersPerAcquisition), ...
                    waitbarHandle, ...
                    sprintf('Completed %u buffers', buffersCompleted));

            % Check if waitbar cancel button was pressed
            if getappdata(waitbarHandle,'canceling')
                break
            end
        end

    end % if bufferFull

end % while ~captureDone

% Save the transfer time
transferTime_sec = toc(startTickCount);

% Close progress window
delete(waitbarHandle);

% Abort the acquisition
retCode = AlazarAbortAsyncRead(boardHandle);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarAbortAsyncRead failed -- %s\n', errorToText(retCode));
end

% Close the data file
if fid ~= -1
    fclose(fid);
end

% Release the buffers
for bufferIndex = 1:bufferCount
    pbuffer = buffers{1, bufferIndex};
    retCode = AlazarFreeBuffer(boardHandle, pbuffer);
    if retCode ~= ApiSuccess
        fprintf('Error: AlazarFreeBuffer failed -- %s\n', errorToText(retCode));
    end
    clear pbuffer;
end

% Display results
if buffersCompleted > 0
    bytesTransferred = double(buffersCompleted) * double(bytesPerBuffer);
    recordsTransferred = recordsPerBuffer * buffersCompleted;

    if transferTime_sec > 0
        buffersPerSec = buffersCompleted / transferTime_sec;
        bytesPerSec = bytesTransferred / transferTime_sec;
        recordsPerSec = recordsTransferred / transferTime_sec;
    else
        buffersPerSec = 0;
        bytesPerSec = 0;
        recordsPerSec = 0.;
    end

    fprintf('Captured %u buffers in %g sec (%g buffers per sec)\n', buffersCompleted, transferTime_sec, buffersPerSec);
    fprintf('Captured %u records (%.4g records per sec)\n', recordsTransferred, recordsPerSec);
    fprintf('Transferred %u bytes (%.4g bytes per sec)\n', bytesTransferred, bytesPerSec);
end

% set return code to indicate success

result = success;
end