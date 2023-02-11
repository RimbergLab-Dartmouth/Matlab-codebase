function [time_out, rts_out, capture_times_distribution, emission_times_distribution] = generate_rts(time, average_capture_time, average_emission_time, initial_state)
    % rts_out switches between states 0 and 1. These can then be rescaled
    % to the appropriate state levels.
    %average_capture time is the average time in state 1, 
    %average_emission_time is the average time in state 0. 
    % the emission and capture processes are Poisson distributed with
    % expectation value of the respective average times.
    
    if ~exist('initial_state','var')
        initial_state = 0;   % if initial_state is not mentioned, assumes initiation in 0 level. 
    end
    
    n = length(time); % total number of sampled time points
    sampling_interval = mean(diff(time));
    verify = max(diff(time) - mean(time));
    rts_out = 5*ones(1,n);
    
    if verify > 1e-15
        error(['time points appear not to be uniform. Vary by ' num2str(verify) 's'])
    end
    
    poisson_capture_mean = round(average_capture_time/sampling_interval); % normalized Poisson mean for capture time
    poisson_emission_mean= round(average_emission_time/sampling_interval); % normalized Poisson mean for emission time
    
    capture_times_distribution = poissrnd(poisson_capture_mean,1,n);
    emission_times_distribution = poissrnd(poisson_emission_mean,1,n);
    
    time_point = 1;
    rts_out = 5*ones(1,n);
    state = initial_state;
    number_captures = 0;
    number_emissions = 0;
   
    while time_point < n + 1
        if state == 0
            if time_point + emission_times_distribution(number_emissions + 1) < n+1
                rts_out(time_point: time_point + emission_times_distribution(number_emissions + 1)) = 0;
            else
                rts_out(time_point: end) = 0;
            end
            state = 1;
            time_point = time_point + emission_times_distribution(number_emissions + 1) + 1;
            number_emissions = number_emissions + 1;
        end
        if state == 1
            if time_point + capture_times_distribution(number_captures + 1) < n+1
                rts_out(time_point: time_point + capture_times_distribution(number_captures + 1)) = 1;
            else
                rts_out(time_point : end) = 0;
            end
            state = 0;
            time_point = time_point + capture_times_distribution(number_captures + 1) + 1;
            number_captures = number_captures + 1;
        end
    end
    time_out = time;
end