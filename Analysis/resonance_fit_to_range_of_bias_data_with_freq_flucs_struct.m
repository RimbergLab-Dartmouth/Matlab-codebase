function[resonance_fits,data_real,data_imag,theory_real,theory_imag,bias_values,err, resonance_fits_min]=resonance_fit_to_range_of_bias_data_with_freq_flucs_struct(data_struct, ...
    gain_prof_struct, flucs_angle_selector, plot_display) %,...
    %gain_profile_log_mag_by_hand,gain_profile_pos_phase_by_hand)
    % flucs_angle_selector can be : 'no_flucs', 'flucs', flucs_and_angle'
 
if ~exist('flucs_angle_selector', 'var')
    flucs_angle_selector = 'flucs';
end
    
if ~exist('plot_display','var')
    plot_display=0;
end
%extract arrays of data from csv files. files used for extracting gain
%profile can be different from (broader scan) current data set

freq_data = reshape(data_struct.freq_zoom, [], size(data_struct.freq_zoom, 3));
log_mag_data = reshape(data_struct.amp_zoom, [], size(data_struct.amp_zoom, 3));
phase_data = reshape(data_struct.phase_zoom, [], size(data_struct.phase_zoom, 3));

% extract arrays of bias data from csv files
bias_values = reshape(data_struct.dc_bias, [], 2);

% initiate null arrays
    [num_bias_points,num_points]=size(log_mag_data);
    data_real=ones(num_bias_points,num_points);
    data_imag=ones(num_bias_points,num_points);
    theory_real=ones(num_bias_points,num_points);
    theory_imag=ones(num_bias_points,num_points);
    err=ones(num_bias_points,1);
    if strcmp(flucs_angle_selector, 'flucs')
        resonance_fits=ones(num_bias_points,4); 
    elseif strcmp(flucs_angle_selector, 'no_flucs')
        resonance_fits=ones(num_bias_points,3); 
    elseif strcmp(flucs_angle_selector, 'flucs_and_angle')
        resonance_fits=ones(num_bias_points,5); 
    end
        
% guesses for fits    
    gamma_int_guess=1e6;
    gamma_ext_guess=1.4e6;
    sigma_guess = 1.5e6;
%     angle_guess=20;
    
%extract and subtract gain profile from all curves. if gain profile
%provided ad hoc, just use that. 

gain_prof_freq_data = gain_prof_struct.freq;
gain_prof_amp = gain_prof_struct.amp;
gain_prof_phase = gain_prof_struct.phase;
gain_prof_amp_interp = zeros(num_bias_points,num_points);
gain_prof_phase_interp = gain_prof_amp_interp;
    for m_bias_point=1:num_bias_points
        gain_prof_amp_interp(m_bias_point,:)=interp1(gain_prof_freq_data(1,:),gain_prof_struct.amp,freq_data(m_bias_point,:),'pchip');
        gain_prof_phase_interp(m_bias_point,:)=interp1(gain_prof_freq_data(1,:),gain_prof_struct.phase,freq_data(m_bias_point,:),'pchip');
        subtracted_log_mag(m_bias_point,:)=log_mag_data(m_bias_point,:)-gain_prof_amp_interp(m_bias_point,:);
        subtracted_phase(m_bias_point,:)=phase_data(m_bias_point,:)-gain_prof_phase_interp(m_bias_point,:);
    end
 %run through  fitting routine for each subtracted data set individually.
 %spits out resonance fit parameters, imag & real data, and imag & real theory
 %scatter to fit parameters
 disp('fitting q circles')
    for m_bias_point=1:num_bias_points
        if strcmp(flucs_angle_selector, 'flucs')
            [temp_fit_struct]=...   
                fit_q_circle_with_freq_flucs(subtracted_log_mag(m_bias_point,:),subtracted_phase(m_bias_point,:),freq_data(m_bias_point,:),gamma_int_guess,gamma_ext_guess,sigma_guess);%,angle_guess);
                resonance_fits(m_bias_point,4) = temp_fit_struct.sigma_fit;
        elseif strcmp(flucs_angle_selector, 'no_flucs')
            [temp_fit_struct]=...   
                fit_q_circle(subtracted_log_mag(m_bias_point,:),subtracted_phase(m_bias_point,:),freq_data(m_bias_point,:),gamma_int_guess,gamma_ext_guess);
        elseif strcmp(flucs_angle_selector, 'flucs_and_angle')
            [temp_fit_struct]=...   
                fit_q_circle_with_freq_flucs_and_angle(subtracted_log_mag(m_bias_point,:),subtracted_phase(m_bias_point,:),freq_data(m_bias_point,:),gamma_int_guess,gamma_ext_guess,sigma_guess);
                resonance_fits(m_bias_point,4) = temp_fit_struct.sigma_fit;
                resonance_fits(m_bias_point,5) = temp_fit_struct.angle_fit;
        end
        err(m_bias_point,1) = temp_fit_struct.goodness_fit;
        resonance_fits(m_bias_point,1) = temp_fit_struct.res_freq_fit;
        resonance_fits(m_bias_point,2) = temp_fit_struct.gamma_int_fit;
        resonance_fits(m_bias_point,3) = temp_fit_struct.gamma_ext_fit;
        data_real(m_bias_point,:) = temp_fit_struct.data_real;
        data_imag(m_bias_point,:) = temp_fit_struct.data_imag;
        theory_real(m_bias_point,:) = temp_fit_struct.theory_real;
        theory_imag(m_bias_point,:) = temp_fit_struct.theory_imag;
        m_bias_point
        resonance_fits_min(m_bias_point,1) = min(subtracted_log_mag(m_bias_point,:));
    end
  disp(['For the Q circle fits, average error was - ' num2str(mean(err)) 13 10 'maximum error was - ' num2str(max(err)) 13 10 ...
      'SD of error was - ' num2str(std(err))]);
  
%extract lin mag and phase in degs based on theory fits
    [theory_lin_mag,theory_phase_radians]=extract_lin_mag_phase_from_real_imag(theory_real,theory_imag,freq_data);
    [theory_log_mag,theory_phase_degs]=extract_log_mag_phase_degs(theory_lin_mag,theory_phase_radians);
  
    % plots the resonance circles for 10 random bias points and the one with
% the worst error
    if plot_display==1
        %%%%%%%%%%%%%check this section for plots of gain profiles%%%%%%
        figure
        subplot(2,1,1)
        plot(gain_prof_freq_data(1,:),gain_prof_amp);
        title('gain profile log mag')
        subplot(2,1,2)
        plot(gain_prof_freq_data(1,:),gain_prof_phase);
        title('gain profile phase')
        
        figure
        subplot(1,3,1)
        [~,b]=max(err);
        scatter(data_real(b,:),data_imag(b,:))
        pbaspect([1 1 1])
        hold on;
        scatter(theory_real(b,:),theory_imag(b,:))
        title(['this was the worst fit @ gate: ' 10 num2str(bias_values(b,1)) 'mV and flux: ' num2str(bias_values(b,2)) 'mV.' 13 10 '\gamma_{int} = ' num2str(resonance_fits(b,2)/1e6)...
            ' MHz and \gamma_{ext} = ' num2str(resonance_fits(b,3)/1e6) 'MHz, \sigma_{\omega_0} = ' num2str(resonance_fits(b,4)/1e6) 'MHz']);

        [~,b]=min(err);
        subplot(1,3,2)
        scatter(data_real(b,:),data_imag(b,:))
        pbaspect([1 1 1])
        hold on;
        scatter(theory_real(b,:),theory_imag(b,:))
        title(['this was the best fit @ gate: ' 10 num2str(bias_values(b,1)) 'mV and flux: ' num2str(bias_values(b,2)) 'mV.' 13 10 '\gamma_{int} = ' num2str(resonance_fits(b,2)/1e6)...
            ' MHz and \gamma_{ext} = ' num2str(resonance_fits(b,3)/1e6) 'MHz, \sigma_{\omega_0} = ' num2str(resonance_fits(b,4)/1e6) 'MHz']);

        deviation=abs(err-mean(err));
        [~,p]=min(deviation);
        subplot(1,3,3)
        scatter(data_real(p,:),data_imag(p,:))
        pbaspect([1 1 1])
        hold on;
        scatter(theory_real(p,:),theory_imag(p,:))
        title(['the average fit looks like this one @ gate: ' 10  num2str(bias_values(p,1)) 'mV and flux: ' num2str(bias_values(p,2)) 'mV.' 13 10 '\gamma_{int} = ' num2str(resonance_fits(p,2)/1e6)...
            ' MHz and \gamma_{ext} = ' num2str(resonance_fits(p,3)/1e6) 'MHz, \sigma_{\omega_0} = ' num2str(resonance_fits(b,4)/1e6) 'MHz']);            

        for j=1:10
            x=randi(num_bias_points);
    %         figure
    %         plot(freq_data(x,:),subtracted_log_mag(x,:))
    %         figure
    %         plot(freq_data(x,:),subtracted_phase(x,:),'.');
            figure
            subplot(1,3,1)
            scatter(data_real(x,:),data_imag(x,:))
            pbaspect([1 1 1])
            hold on;
            scatter(theory_real(x,:),theory_imag(x,:))
            xlabel('\Gamma_{real}')
            ylabel('\Gamma_{imag}')
            title(['resonance circles for ' num2str(bias_values(x,1)) 'mV gate bias, ' num2str(bias_values(x,2)) 'mV flux bias.' 13 10 '\gamma_{int} = ' num2str(resonance_fits(x,2)/1e6)...
            ' MHz and \gamma_{ext} = ' num2str(resonance_fits(x,3)/1e6) 'MHz, \sigma_{\omega_0} = ' num2str(resonance_fits(b,4)/1e6) 'MHz']);
            subplot(1,3,2)
            plot(freq_data(x,:),subtracted_log_mag(x,:),'.',freq_data(x,:),theory_log_mag(x,:));
            title('subtracted amplitude and fit')
            xlabel('Freq (Hz)')
            ylabel('S21 (dB)')
            subplot(1,3,3)
            plot(freq_data(x,:),subtracted_phase(x,:),'.',freq_data(x,:),theory_phase_degs(x,:));
            xlabel('Freq (Hz)')
            ylabel('S21 (degs)')
        end
    end   
    if plot_display
        user=input('continue?. 0/1');
        if user == 1
            close all
            return
        end
    end
    
    %%% reshape output structures to original bias point dimensions if flux
    %%% and gate bias input separately (as for q_circle bias point scans)
    if ndims(data_struct.freq_zoom) == 3
        resonance_fits = reshape(resonance_fits, size(data_struct.freq_zoom, 1), size(data_struct.freq_zoom, 2), []);
        data_real = reshape(data_real, size(data_struct.freq_zoom, 1), size(data_struct.freq_zoom, 2), []);
        data_imag = reshape(data_imag, size(data_struct.freq_zoom, 1), size(data_struct.freq_zoom, 2), []);
        theory_real = reshape(theory_real, size(data_struct.freq_zoom, 1), size(data_struct.freq_zoom, 2), []);
        theory_imag = reshape(theory_imag, size(data_struct.freq_zoom, 1), size(data_struct.freq_zoom, 2), []);
        bias_values = reshape(bias_values, size(data_struct.freq_zoom, 1), size(data_struct.freq_zoom, 2), []);
        err = reshape(err, size(data_struct.freq_zoom, 1), size(data_struct.freq_zoom, 2), []);
        resonance_fits_min = reshape(resonance_fits_min, size(data_struct.freq_zoom, 1), size(data_struct.freq_zoom, 2), []);    
    end
end
