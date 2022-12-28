function [freq,gain_prof_amp,gain_prof_phase]=extract_gain_profile_v2_struct(data_freq, data_amp, data_phase, rough_gain_profile_struct, exclude_span, plot_display)

    if ~exist('plot_display','var')
        plot_display = 0;
    end
    if ~exist('exclude_span','var')
        exclude_span = 15e6;
    end
    %%%%%% parameters %%%%%%%%%%%%%%% 
    span_amp_exclude = exclude_span;% number to exclude (total) on each side of resonance in amp data. will depend on total damping rate
    span_phase_exclude = exclude_span;
    num_to_plot = 4;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% extract and check data
    number_points = size(data_freq,3);
    number_traces = size(data_freq,1) * size(data_freq,2);
    
    freq_temp = squeeze(reshape(data_freq, [], number_points));
    log_mag_data = squeeze(reshape(data_amp, [], number_points));
    phase_data = squeeze(reshape(data_phase, [], number_points));
    
    gain_prof_amp = zeros(1,number_points);
    gain_prof_phase = zeros(1,number_points);
    gain_prof_amp_total = gain_prof_amp;
    gain_prof_phase_total = gain_prof_phase;
    
    if mean(std(freq_temp,[],1)) ~= 0
        disp('check freqs')
        return
    else
        freq = freq_temp(1,:);
    end
    data_span = freq(1,end) - freq(1,1);
    
    number_amp_exclude = ceil(span_amp_exclude/data_span/2*number_points);
    number_phase_exclude = ceil(span_phase_exclude/data_span/2*number_points);
    
    weight_array_amp = zeros(1,number_points);
	weight_array_phase = zeros(1,number_points);
    
    [~,res_freqs_indices] = min(log_mag_data - rough_gain_profile_struct.amp',[],2);
    res_freqs = freq(res_freqs_indices);
    
    sub_data_amp = log_mag_data;
    sub_phase_data = phase_data;
    skipped = 0;
    i = 1;
    while i < number_traces 
        if res_freqs_indices(i) - number_amp_exclude < 1 || res_freqs_indices(i) + number_amp_exclude > number_points
            skipped = skipped + 1;
            i = i + 1;
            continue
        end
        weight_array_amp = weight_array_amp +1;
        weight_array_phase = weight_array_phase +1;
        sub_data_amp(i,res_freqs_indices(i) - number_amp_exclude : res_freqs_indices(i) + number_amp_exclude) = 0;
        gain_prof_amp_total = gain_prof_amp_total + sub_data_amp(i,:);
        weight_array_amp (1,res_freqs_indices(i) - number_amp_exclude : res_freqs_indices(i) + number_amp_exclude) = ...
            weight_array_amp(1,res_freqs_indices(i) - number_amp_exclude : res_freqs_indices(i) + number_amp_exclude) - 1;
        sub_phase_data(i,res_freqs_indices(i) - number_phase_exclude : res_freqs_indices(i) + number_phase_exclude) = 0;
        gain_prof_phase_total = gain_prof_phase_total + sub_phase_data(i,:);
        weight_array_phase (1,res_freqs_indices(i) - number_phase_exclude : res_freqs_indices(i) + number_phase_exclude) = ...
            weight_array_phase(1,res_freqs_indices(i) - number_phase_exclude : res_freqs_indices(i) + number_phase_exclude) - 1;
        i = i+1;
    end
    gain_prof_amp = gain_prof_amp_total./weight_array_amp;
    gain_prof_phase = gain_prof_phase_total./weight_array_phase;
    if plot_display == 1
        disp('plotting')
        figure
        subplot(2,1,1)
        plot(freq,gain_prof_amp,'DisplayName','gain profile')
        hold on
        plot_index = randperm(number_traces);
        min(num_to_plot, size(log_mag_data, 1))
        for i = 1: min(num_to_plot, size(log_mag_data, 1))
            plot(freq,log_mag_data(plot_index(i),:))
        end
        legend show
        subplot(2,1,2)
        plot(freq,gain_prof_phase,'DisplayName','gain profile')
        hold on
        for i = 1: min(num_to_plot, size(log_mag_data, 1))
            plot(freq,phase_data(plot_index(i),:))
        end
        legend show
    end
    skipped
end
    
    
    