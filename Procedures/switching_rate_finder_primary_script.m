%%%% ensure that a 'bias_point_struct' is initialized in the workspace which
%%%% contains :
%%%% flux_zero_voltage, flux_period, gate_offset, gate_period,
%%%% flux_center_freq_mean, gate_values_gate and res_freqs_gate
%%%% and a 'gain_profile_struct' that contains :
%%%% freq, amp, phase
run_params.file_name = 'switching_finder_comprehensive_data.mat';
run_params.concatenate_runs = 1; % 0/1 - decides whether this run is going to concatenate data to an existing file
run_params.redo_previously_saved_run = 0; % if this is the same as the previous run, redone for some reason, this will make sure it is overwritten.
run_params.data_directory = [cd '\data'];
run_params.set_with_pre_recorded = 1; %%% verify set res freq with one saved in a pre recorded data set.
m_bias_point = 1;
m_power = 1;
run_params.ng_1_value = 0;
run_params.flux_1_value = 0.11;
run_params.input_power_value = -119; % power at the sample, adjusted using fridge attenuation and additional attenuation params.

run_params.detuning_point_start = -45; % in MHz
run_params.detuning_point_end = -2; % in MHz. 
run_params.detuning_point_step = 0.5; % in MHz.
m_detuning_start = (run_params.detuning_point_start + 50)/0.5 + 1;
%%% deliberately make expected detuning number large so dont have to worry
%%% about variation in array size. each array point corresponds to -50MHz to
%%% +50, steps of 0.5
run_params.detuning_array_number = 201;
run_params.detuning_expected_number = abs((run_params.detuning_point_start - run_params.detuning_point_end)/ run_params.detuning_point_step) + 1;
run_params.number_repetitions = 2;  

%%%%% load gain profile and bias point
if ~exist('gain_prof', 'var')
    disp('enter directory where gain_prof_struct.mat is saved')
   load_directory = uigetdir('enter directory where gain_prof_struct.mat is saved');
   load([load_directory '\gain_prof_struct.mat'], 'gain_prof')
   clear load_directory
end

if ~exist('bias_point', 'var')
    disp('enter directory where bias_point_struct.mat is saved')
   load_directory = uigetdir;
   load([load_directory '\bias_point_struct.mat'], 'bias_point')
   clear load_directory
end

if ~isfield(run_params, 'pre_recorded')
    disp('enter directory where pre_recorded_values.mat is saved')
   load_directory = uigetdir;
   load([load_directory '\pre_recorded_values.mat'], 'pre_recorded')
   run_params.pre_recorded_struct = pre_recorded;
   clear load_directory ...
         pre_recorded
end
%%%%%%%%%%

date = datetime('now','format', 'yyyy-MM-dd HH:mm:ss Z');
date = char(date);
run_params.awg_switching_directory_name = 'sw';
run_params.awg_directory = ['/' run_params.awg_switching_directory_name '/' date(1:7)];
clear date;
run_params.save_data_and_png_param = 1; % 0/1 - decides whether to save data and figs or not. 
run_params.save_fig_file_param = 0; % fig file for actual time trace of phase. usually very large for ms data at high sampling
run_params.plot_visible = 1;
run_params.fig_directory = [cd '\plots\'];
run_params.rts_fig_directory = [cd '\plots\rts\'];
run_params.data_directory = [cd '\data\'];

if run_params.concatenate_runs == 1 && m_bias_point ~= 1 && m_power ~= 1
    load([run_params.data_directory '\' run_params.file_name], '-regexp', '^(?!(run_params)$).')   
end

if ~exist('input_params', 'var')
    input_params.run_number = 0;
elseif run_params.redo_previously_saved_run == 1
    input_params.run_number = input_params.run_number - 1;
end 
input_params.run_number = input_params.run_number + 1;

if m_bias_point == 1 && m_power == 1
    %% create folders
    if run_params.save_data_and_png_param == 1
        mkdir([cd '\data'])
        mkdir([cd '\plots'])
        mkdir([cd '\plots\fig_files'])
        mkdir([cd '\plots\rts'])
        mkdir([cd '\plots\rts\fig_files'])
    end
    %% Attenuation values
    input_params.fridge_attenuation = 82.9;
    input_params.additional_attenuation = 35.82; % dB. big fridge setup as of 12/31/2022. see notes.txt in folder below
    %%%%\\dartfs-hpc\rc\lab\R\RimbergA\cCPT_NR_project\Bhar_measurements\2022_December_Jules_sample\AWG_input_attenuation_calibration
    %% Analysis params
    input_params.if_freq = 21e6; % freq to which output signal is mixed down
    input_params.analysis.clean_RTS_bin_width = 6; % degs - phase histogramming bin size
    run_params.analysis.moving_mean_average_time = 3; % in us
    run_params.analysis.number_iterations = 5; % number of iterations for the clean RTS algorithm
    input_params.analysis.phase_outlier_cutoff = 45; % in degs, this is the phase above and below the mean phase, over which the phase is classified as an outlier (after moving mean)
    run_params.analysis.min_gaussian_center_to_center_phase = 15; % in degs, this is the minimum distance between gaussian centers that the double gaussian fit accepts
    run_params.analysis.max_gaussian_center_to_center_phase = 60; % in degs
    input_params.analysis.min_gaussian_count = 1500;
    input_params.minimum_number_switches = 100;
    run_params.analysis.double_gaussian_fit_sigma_guess = 15; % degs
    run_params.analysis.plotting_time_for_RTS = 50e-6;
    input_params.time_length_of_RTS_raw_data_to_store = 50e-6; % in s
    input_params.start_time_of_RTS_raw_data_to_store = 5.1e-3; % in s
    run_params.poissonian_fit_bin_number = 25;
    %% VNA parameter settings
    input_params.vna.average_number = 50;
    input_params.vna.IF_BW = 1e3;
    input_params.vna.number_points = 201;
    run_params.vna.power = run_params.input_power_value + input_params.fridge_attenuation;
    input_params.vna.rough_center = 5.76e9;
    input_params.vna.rough_span = 250e6;
    input_params.vna.rough_IF_BW = 10e3;
    input_params.vna.zoom_scan_span = 30e6;
    input_params.vna.rough_number_points = 1601;
    input_params.vna.electrical_delay = 62.6e-9; 
    
    input_params.q_circle_fit.gamma_int_guess = .2e6;
    input_params.q_circle_fit.gamma_ext_guess = 1.2e6;
    input_params.q_circle_fit.sigma_guess = .5e6;
    %% Digitizer params
    input_params.digitizer.data_collection_time = 5e-2; % in seconds. the time to monitor phase and look for switching events
    input_params.digitizer.sample_rate = 168e6;
    input_params.digitizer.trigger_level = 225; %225 is ~+0.75V for 2Vpp trigger such as marker from AWG
    %% AWG and pulse params params
    input_params.awg.clock = 840e6; % the code is designed for this to be at 840MS/s
    input_params.awg.input_IF_waveform_freq = 84e6; % the IF to IQ4509 is at 84MHz, defined in the AWG waveforms
    run_params.awg.output_power = run_params.input_power_value + input_params.fridge_attenuation + input_params.additional_attenuation;
    input_params.awg.stabilization_buffer_time = 10e-6; % time to stabilize cavity amplitude before recording phase - has to be multiple of 1us
    input_params.awg.continuous_amplitude_down_time = 100e-6; % down time between repeating pulses. (though only one is usually recorded)
    run_params.awg.sequence = [num2str(round(run_params.awg.output_power, 1)) 'dBm_' num2str(round(input_params.digitizer.data_collection_time*1e3),1) 'ms_data_collect.seq'];
end

%%%%%%%%%%
disp(['input power number = ' num2str(m_power) 13 10 ...
    'input power = ' num2str(run_params.input_power_value) 'dBm' 13 10 ...
    'bias point number = ' num2str(m_bias_point) 13 10 ...
    'bias point is ng = ' num2str(run_params.ng_1_value) ', flux = ' num2str(run_params.flux_1_value) 13 10 ...
    'correct bias point number and bias point calibration?'])
pause

%% initialize arrays 
if m_bias_point == 1 && m_power == 1
    %% arrays for VNA data and analysis single photon
    data.vna.single_photon.rough.freq = zeros(1, 1, input_params.vna.rough_number_points);
    data.vna.single_photon.rough.amp = zeros(1, 1, input_params.vna.rough_number_points);
    data.vna.single_photon.rough.phase = zeros(1, 1, input_params.vna.rough_number_points);
    data.vna.single_photon.rough.real = zeros(1, 1, input_params.vna.rough_number_points);
    data.vna.single_photon.rough.imag = zeros(1, 1, input_params.vna.rough_number_points);
    
    data.vna.single_photon.fine.freq = zeros(1, 1, input_params.vna.number_points);
    data.vna.single_photon.fine.amp = zeros(1, 1, input_params.vna.number_points);
    data.vna.single_photon.fine.phase = zeros(1, 1, input_params.vna.number_points);
    data.vna.single_photon.fine.real = zeros(1, 1, input_params.vna.number_points);
    data.vna.single_photon.fine.imag = zeros(1, 1, input_params.vna.number_points);
    
    analysis.vna.single_photon.fits_no_flucs.real = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.fits_no_flucs.imag = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.fits_no_flucs.amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.fits_no_flucs.phase = zeros(1, 1, input_params.vna.number_points);
    
    analysis.vna.single_photon.fits_flucs_no_angle.real = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.fits_flucs_no_angle.imag = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.fits_flucs_no_angle.amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.fits_flucs_no_angle.phase = zeros(1, 1, input_params.vna.number_points);
    
    analysis.vna.single_photon.fits_flucs_and_angle.real = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.fits_flucs_and_angle.imag = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.fits_flucs_and_angle.amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.fits_flucs_and_angle.phase = zeros(1, 1, input_params.vna.number_points);
    
    analysis.vna.single_photon.interp_gain_amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.interp_gain_phase = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.subtracted_amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.single_photon.subtracted_phase  = zeros(1, 1, input_params.vna.number_points);
    
    analysis.vna.single_photon.fits_no_flucs.gamma_ext = zeros(1, 1);
    analysis.vna.single_photon.fits_no_flucs.gamma_int = zeros(1, 1);
    analysis.vna.single_photon.fits_no_flucs.res_freq = zeros(1, 1);
    analysis.vna.single_photon.fits_no_flucs.goodness_fit = zeros(1, 1);
        
    analysis.vna.single_photon.fits_flucs_no_angle.gamma_ext = zeros(1, 1);
    analysis.vna.single_photon.fits_flucs_no_angle.gamma_int = zeros(1, 1);
    analysis.vna.single_photon.fits_flucs_no_angle.res_freq = zeros(1, 1);
    analysis.vna.single_photon.fits_flucs_no_angle.sigma = zeros(1, 1);
    analysis.vna.single_photon.fits_flucs_no_angle.goodness_fit = zeros(1, 1);
    
    analysis.vna.single_photon.fits_flucs_and_angle.gamma_ext = zeros(1, 1);
    analysis.vna.single_photon.fits_flucs_and_angle.gamma_int = zeros(1, 1);
    analysis.vna.single_photon.fits_flucs_and_angle.res_freq = zeros(1, 1);
    analysis.vna.single_photon.fits_flucs_and_angle.sigma = zeros(1, 1);
    analysis.vna.single_photon.fits_flucs_and_angle.angle = zeros(1, 1); 
    analysis.vna.single_photon.fits_flucs_and_angle.goodness_fit = zeros(1, 1); 
    
    %% arrays for vna data and analysis actual power
    data.vna.actual_power.rough.freq = zeros(1, 1, input_params.vna.rough_number_points);
    data.vna.actual_power.rough.amp = zeros(1, 1, input_params.vna.rough_number_points);
    data.vna.actual_power.rough.phase = zeros(1, 1, input_params.vna.rough_number_points);
    data.vna.actual_power.rough.real = zeros(1, 1, input_params.vna.rough_number_points);
    data.vna.actual_power.rough.imag = zeros(1, 1, input_params.vna.rough_number_points);
    
    data.vna.actual_power.fine.freq = zeros(1, 1, input_params.vna.number_points);
    data.vna.actual_power.fine.amp = zeros(1, 1, input_params.vna.number_points);
    data.vna.actual_power.fine.phase = zeros(1, 1, input_params.vna.number_points);
    data.vna.actual_power.fine.real = zeros(1, 1, input_params.vna.number_points);
    data.vna.actual_power.fine.imag = zeros(1, 1, input_params.vna.number_points);
    
    analysis.vna.actual_power.interp_gain_amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.interp_gain_phase  = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.subtracted_amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.subtracted_phase  = zeros(1, 1, input_params.vna.number_points);
    
    analysis.vna.actual_power.fits_flucs_no_angle.real = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.fits_flucs_no_angle.imag = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.fits_flucs_no_angle.amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.fits_flucs_no_angle.phase = zeros(1, 1, input_params.vna.number_points);
    
    analysis.vna.actual_power.fits_flucs_and_angle.real = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.fits_flucs_and_angle.imag = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.fits_flucs_and_angle.amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.fits_flucs_and_angle.phase = zeros(1, 1, input_params.vna.number_points);
    
    analysis.vna.actual_power.interp_gain_amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.interp_gain_phase = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.subtracted_amp = zeros(1, 1, input_params.vna.number_points);
    analysis.vna.actual_power.subtracted_phase  = zeros(1, 1, input_params.vna.number_points);
    
    analysis.vna.actual_power.fits_no_flucs.gamma_ext = zeros(1, 1);
    analysis.vna.actual_power.fits_no_flucs.gamma_int = zeros(1, 1);
    analysis.vna.actual_power.fits_no_flucs.res_freq = zeros(1, 1);
    analysis.vna.actual_power.fits_no_flucs.goodness_fit = zeros(1, 1);
        
    analysis.vna.actual_power.fits_flucs_no_angle.gamma_ext = zeros(1, 1);
    analysis.vna.actual_power.fits_flucs_no_angle.gamma_int = zeros(1, 1);
    analysis.vna.actual_power.fits_flucs_no_angle.res_freq = zeros(1, 1);
    analysis.vna.actual_power.fits_flucs_no_angle.sigma = zeros(1, 1);
    analysis.vna.actual_power.fits_flucs_no_angle.goodness_fit = zeros(1, 1);
    
    analysis.vna.actual_power.fits_flucs_and_angle.gamma_ext = zeros(1, 1);
    analysis.vna.actual_power.fits_flucs_and_angle.gamma_int = zeros(1, 1);
    analysis.vna.actual_power.fits_flucs_and_angle.res_freq = zeros(1, 1);
    analysis.vna.actual_power.fits_flucs_and_angle.sigma = zeros(1, 1);
    analysis.vna.actual_power.fits_flucs_and_angle.angle = zeros(1, 1); 
    analysis.vna.actual_power.fits_flucs_and_angle.goodness_fit = zeros(1, 1); 
    
    %% other data arrays
    data.detunings = zeros(1, 1, run_params.detuning_array_number, run_params.number_repetitions);
    data.recorded_res_freq = zeros(1, 1, run_params.detuning_array_number);
    data.peripheral.awg_output_power = zeros(1, 1, run_params.detuning_array_number);
    data.lifetime_state_1_run_data = zeros(1, 1, run_params.detuning_array_number, run_params.number_repetitions);
    data.lifetime_state_2_run_data = zeros(1, 1, run_params.detuning_array_number, run_params.number_repetitions);
    data.gaussian_state_1_mean_run_data = zeros(1, 1, run_params.detuning_array_number, run_params.number_repetitions);
    data.gaussian_state_2_mean_run_data = zeros(1, 1, run_params.detuning_array_number, run_params.number_repetitions);
    data.sigma_gaussian_run_data = zeros(1, 1, run_params.detuning_array_number, run_params.number_repetitions);
    data.double_gaussian_fit_error_run_data = zeros(1, 1, run_params.detuning_array_number, run_params.number_repetitions);
    data.area_gaussian_1_run_data = zeros(1, 1,run_params.detuning_array_number, run_params.number_repetitions); 
    data.area_gaussian_2_run_data = zeros(1, 1,run_params.detuning_array_number, run_params.number_repetitions); 
    data.theory_hist_phases_run_data = zeros(1, 1,run_params.detuning_array_number, run_params.number_repetitions, 360/input_params.analysis.clean_RTS_bin_width); 
    data.theory_gaussian_1_run_data = zeros(1, 1,run_params.detuning_array_number, run_params.number_repetitions, 360/input_params.analysis.clean_RTS_bin_width); 
    data.theory_gaussian_2_run_data = zeros(1, 1,run_params.detuning_array_number, run_params.number_repetitions, 360/input_params.analysis.clean_RTS_bin_width); 
    data.switch_finder_hist_phases_run_data = zeros(1, 1,run_params.detuning_array_number, run_params.number_repetitions, 360/input_params.analysis.clean_RTS_bin_width); 
    data.switch_finder_hists_run_data = zeros(1, 1,run_params.detuning_array_number, run_params.number_repetitions, 360/input_params.analysis.clean_RTS_bin_width); 
    data.poisson_lifetime_state_1_array = zeros(1, 1,run_params.detuning_array_number,1);
    data.poisson_lifetime_state_2_array = zeros(1, 1,run_params.detuning_array_number,1);
    data.poisson_error_lifetime_1_in_us_array = zeros(1, 1,run_params.detuning_array_number, 2);
    data.poisson_error_lifetime_2_in_us_array = zeros(1, 1,run_params.detuning_array_number, 2);
else
    %% arrays for VNA data and analysis single photon
    data.vna.single_photon.rough.freq = [data.vna.single_photon.rough.freq; zeros(1, 1, input_params.vna.rough_number_points)];
    data.vna.single_photon.rough.amp = [data.vna.single_photon.rough.amp; zeros(1, 1, input_params.vna.rough_number_points)];
    data.vna.single_photon.rough.phase = [data.vna.single_photon.rough.phase; zeros(1, 1, input_params.vna.rough_number_points)];
    data.vna.single_photon.rough.real = [data.vna.single_photon.rough.real; zeros(1, 1, input_params.vna.rough_number_points)];
    data.vna.single_photon.rough.imag = [data.vna.single_photon.rough.imag; zeros(1, 1, input_params.vna.rough_number_points)];
    
    data.vna.single_photon.fine.freq = [data.vna.single_photon.fine.freq; zeros(1, 1, input_params.vna.number_points)];
    data.vna.single_photon.fine.amp = [data.vna.single_photon.fine.amp; zeros(1, 1, input_params.vna.number_points)];
    data.vna.single_photon.fine.phase = [data.vna.single_photon.fine.phase; zeros(1, 1, input_params.vna.number_points)];
    data.vna.single_photon.fine.real = [data.vna.single_photon.fine.real; zeros(1, 1, input_params.vna.number_points)];
    data.vna.single_photon.fine.imag = [data.vna.single_photon.fine.imag; zeros(1, 1, input_params.vna.number_points)];
    
    analysis.vna.single_photon.interp_gain_amp = [analysis.vna.single_photon.interp_gain_amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.interp_gain_phase = [analysis.vna.single_photon.interp_gain_phase; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.subtracted_amp = [analysis.vna.single_photon.subtracted_amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.subtracted_phase  = [analysis.vna.single_photon.subtracted_phase; zeros(1, 1, input_params.vna.number_points)];
    
    analysis.vna.single_photon.fits_flucs_no_angle.real = ...
        [analysis.vna.single_photon.fits_flucs_no_angle.real; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.fits_flucs_no_angle.imag = ...
        [analysis.vna.single_photon.fits_flucs_no_angle.imag; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.fits_flucs_no_angle.amp = ...
        [analysis.vna.single_photon.fits_flucs_no_angle.amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.fits_flucs_no_angle.phase = ...
        [analysis.vna.single_photon.fits_flucs_no_angle.phase; zeros(1, 1, input_params.vna.number_points)];
    
    analysis.vna.single_photon.fits_flucs_and_angle.real = ...
        [analysis.vna.single_photon.fits_flucs_and_angle.real; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.fits_flucs_and_angle.imag = ...
        [analysis.vna.single_photon.fits_flucs_and_angle.imag; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.fits_flucs_and_angle.amp = ...
        [analysis.vna.single_photon.fits_flucs_and_angle.amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.fits_flucs_and_angle.phase = ...
        [analysis.vna.single_photon.fits_flucs_and_angle.phase; zeros(1, 1, input_params.vna.number_points)];
    
    analysis.vna.single_photon.interp_gain_amp = ...
        [analysis.vna.single_photon.interp_gain_amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.interp_gain_phase = ...
        [analysis.vna.single_photon.interp_gain_phase; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.subtracted_amp = ...
        [analysis.vna.single_photon.subtracted_amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.single_photon.subtracted_phase = ...
        [analysis.vna.single_photon.subtracted_phase; zeros(1, 1, input_params.vna.number_points)];
    
    analysis.vna.single_photon.fits_no_flucs.gamma_ext = [analysis.vna.single_photon.fits_no_flucs.gamma_ext; zeros(1, 1)];
    analysis.vna.single_photon.fits_no_flucs.gamma_int = [analysis.vna.single_photon.fits_no_flucs.gamma_int; zeros(1, 1)];
    analysis.vna.single_photon.fits_no_flucs.res_freq = [analysis.vna.single_photon.fits_no_flucs.res_freq; zeros(1, 1)];
    analysis.vna.single_photon.fits_no_flucs.goodness_fit = [analysis.vna.single_photon.fits_no_flucs.goodness_fit; zeros(1, 1)];
        
    analysis.vna.single_photon.fits_flucs_no_angle.gamma_ext = [analysis.vna.single_photon.fits_flucs_no_angle.gamma_ext; zeros(1, 1)];
    analysis.vna.single_photon.fits_flucs_no_angle.gamma_int = [analysis.vna.single_photon.fits_flucs_no_angle.gamma_int; zeros(1, 1)];
    analysis.vna.single_photon.fits_flucs_no_angle.res_freq = [analysis.vna.single_photon.fits_flucs_no_angle.res_freq; zeros(1, 1)];
    analysis.vna.single_photon.fits_flucs_no_angle.sigma = [analysis.vna.single_photon.fits_flucs_no_angle.sigma; zeros(1, 1)];
    analysis.vna.single_photon.fits_flucs_no_angle.goodness_fit = [analysis.vna.single_photon.fits_flucs_no_angle.goodness_fit; zeros(1, 1)];
    
    analysis.vna.single_photon.fits_flucs_and_angle.gamma_ext = [analysis.vna.single_photon.fits_flucs_and_angle.gamma_ext; zeros(1, 1)];
    analysis.vna.single_photon.fits_flucs_and_angle.gamma_int = [analysis.vna.single_photon.fits_flucs_and_angle.gamma_int; zeros(1, 1)];
    analysis.vna.single_photon.fits_flucs_and_angle.res_freq = [analysis.vna.single_photon.fits_flucs_and_angle.res_freq; zeros(1, 1)];
    analysis.vna.single_photon.fits_flucs_and_angle.sigma = [analysis.vna.single_photon.fits_flucs_and_angle.sigma; zeros(1, 1)];
    analysis.vna.single_photon.fits_flucs_and_angle.angle = [analysis.vna.single_photon.fits_flucs_and_angle.angle; zeros(1, 1)]; 
    analysis.vna.single_photon.fits_flucs_and_angle.goodness_fit = [analysis.vna.single_photon.fits_flucs_and_angle.goodness_fit; zeros(1, 1)]; 
    
    %% arrays for vna data and analysis actual power
    data.vna.actual_power.rough.freq = [data.vna.actual_power.rough.freq; zeros(1, 1, input_params.vna.rough_number_points)];
    data.vna.actual_power.rough.amp = [data.vna.actual_power.rough.amp; zeros(1, 1, input_params.vna.rough_number_points)];
    data.vna.actual_power.rough.phase = [data.vna.actual_power.rough.phase; zeros(1, 1, input_params.vna.rough_number_points)];
    data.vna.actual_power.rough.real = [data.vna.actual_power.rough.real; zeros(1, 1, input_params.vna.rough_number_points)];
    data.vna.actual_power.rough.imag = [data.vna.actual_power.rough.imag; zeros(1, 1, input_params.vna.rough_number_points)];
    
    data.vna.actual_power.fine.freq = [data.vna.actual_power.fine.freq; zeros(1, 1, input_params.vna.number_points)];
    data.vna.actual_power.fine.amp = [data.vna.actual_power.fine.amp; zeros(1, 1, input_params.vna.number_points)];
    data.vna.actual_power.fine.phase = [data.vna.actual_power.fine.phase; zeros(1, 1, input_params.vna.number_points)];
    data.vna.actual_power.fine.real = [data.vna.actual_power.fine.real; zeros(1, 1, input_params.vna.number_points)];
    data.vna.actual_power.fine.imag = [data.vna.actual_power.fine.imag; zeros(1, 1, input_params.vna.number_points)];
    
    analysis.vna.actual_power.interp_gain_amp = [analysis.vna.actual_power.interp_gain_amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.interp_gain_phase = [analysis.vna.actual_power.interp_gain_phase; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.subtracted_amp = [analysis.vna.actual_power.subtracted_amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.subtracted_phase  = [analysis.vna.actual_power.subtracted_phase; zeros(1, 1, input_params.vna.number_points)];
    
    analysis.vna.actual_power.fits_flucs_no_angle.real = ...
        [analysis.vna.actual_power.fits_flucs_no_angle.real; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.fits_flucs_no_angle.imag = ...
        [analysis.vna.actual_power.fits_flucs_no_angle.imag; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.fits_flucs_no_angle.amp = ...
        [analysis.vna.actual_power.fits_flucs_no_angle.amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.fits_flucs_no_angle.phase = ...
        [analysis.vna.actual_power.fits_flucs_no_angle.phase; zeros(1, 1, input_params.vna.number_points)];
    
    analysis.vna.actual_power.fits_flucs_and_angle.real = ...
        [analysis.vna.actual_power.fits_flucs_and_angle.real; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.fits_flucs_and_angle.imag = ...
        [analysis.vna.actual_power.fits_flucs_and_angle.imag; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.fits_flucs_and_angle.amp = ...
        [analysis.vna.actual_power.fits_flucs_and_angle.amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.fits_flucs_and_angle.phase = ...
        [analysis.vna.actual_power.fits_flucs_and_angle.phase; zeros(1, 1, input_params.vna.number_points)];
    
    analysis.vna.actual_power.interp_gain_amp = ...
        [analysis.vna.actual_power.interp_gain_amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.interp_gain_phase = ...
        [analysis.vna.actual_power.interp_gain_phase; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.subtracted_amp = ...
        [analysis.vna.actual_power.subtracted_amp; zeros(1, 1, input_params.vna.number_points)];
    analysis.vna.actual_power.subtracted_phase = ...
        [analysis.vna.actual_power.subtracted_phase; zeros(1, 1, input_params.vna.number_points)];
    
    analysis.vna.actual_power.fits_no_flucs.gamma_ext = [analysis.vna.actual_power.fits_no_flucs.gamma_ext; zeros(1, 1)];
    analysis.vna.actual_power.fits_no_flucs.gamma_int = [analysis.vna.actual_power.fits_no_flucs.gamma_int; zeros(1, 1)];
    analysis.vna.actual_power.fits_no_flucs.res_freq = [analysis.vna.actual_power.fits_no_flucs.res_freq; zeros(1, 1)];
    analysis.vna.actual_power.fits_no_flucs.goodness_fit = [analysis.vna.actual_power.fits_no_flucs.goodness_fit; zeros(1, 1)];
        
    analysis.vna.actual_power.fits_flucs_no_angle.gamma_ext = [analysis.vna.actual_power.fits_flucs_no_angle.gamma_ext; zeros(1, 1)];
    analysis.vna.actual_power.fits_flucs_no_angle.gamma_int = [analysis.vna.actual_power.fits_flucs_no_angle.gamma_int; zeros(1, 1)];
    analysis.vna.actual_power.fits_flucs_no_angle.res_freq = [analysis.vna.actual_power.fits_flucs_no_angle.res_freq; zeros(1, 1)];
    analysis.vna.actual_power.fits_flucs_no_angle.sigma = [analysis.vna.actual_power.fits_flucs_no_angle.sigma; zeros(1, 1)];
    analysis.vna.actual_power.fits_flucs_no_angle.goodness_fit = [analysis.vna.actual_power.fits_flucs_no_angle.goodness_fit; zeros(1, 1)];
    
    analysis.vna.actual_power.fits_flucs_and_angle.gamma_ext = [analysis.vna.actual_power.fits_flucs_and_angle.gamma_ext; zeros(1, 1)];
    analysis.vna.actual_power.fits_flucs_and_angle.gamma_int = [analysis.vna.actual_power.fits_flucs_and_angle.gamma_int; zeros(1, 1)];
    analysis.vna.actual_power.fits_flucs_and_angle.res_freq = [analysis.vna.actual_power.fits_flucs_and_angle.res_freq; zeros(1, 1)];
    analysis.vna.actual_power.fits_flucs_and_angle.sigma = [analysis.vna.actual_power.fits_flucs_and_angle.sigma; zeros(1, 1)];
    analysis.vna.actual_power.fits_flucs_and_angle.angle = [analysis.vna.actual_power.fits_flucs_and_angle.angle; zeros(1, 1)]; 
    analysis.vna.actual_power.fits_flucs_and_angle.goodness_fit = [analysis.vna.actual_power.fits_flucs_and_angle.goodness_fit; zeros(1, 1)]; 
    
    %% other data arrays 
    data.detunings = [data.lifetime_state_1_run_data; zeros(1, 1, run_params.detuning_array_number, run_params.number_repetitions)];
    data.recorded_res_freq = [data.recorded_res_freq; zeros(1, 1)];
    data.peripheral.awg_output_power = [data.peripherals.awg_output_power; zeros(1, 1, run_params.detuning_array_number)];
    data.lifetime_state_1_run_data = [data.lifetime_state_1_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions)]; 
    data.lifetime_state_2_run_data = [data.lifetime_state_2_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions)]; 
    data.gaussian_state_1_mean_run_data = [data.gaussian_state_1_mean_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions)]; 
    data.gaussian_state_2_mean_run_data = [data.gaussian_state_2_mean_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions)]; 
    data.sigma_gaussian_run_data = [data.sigma_gaussian_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions)]; 
    data.double_gaussian_fit_error_run_data = [data.double_gaussian_fit_error_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions)]; 
    data.area_gaussian_1_run_data = [data.area_gaussian_1_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions)]; 
    data.area_gaussian_2_run_data = [data.area_gaussian_2_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions)]; 
    data.theory_hist_phases_run_data = [data.theory_hist_phases_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions, 360/input_params.analysis.clean_RTS_bin_width)]; 
    data.theory_gaussian_1_run_data = [data.theory_gaussian_1_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions, 360/input_params.analysis.clean_RTS_bin_width)]; 
    data.theory_gaussian_2_run_data = [data.theory_gaussian_2_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions, 360/input_params.analysis.clean_RTS_bin_width)]; 
    data.switch_finder_hist_phases_run_data = [data.switch_finder_hist_phases_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions, 360/input_params.analysis.clean_RTS_bin_width)]; 
    data.switch_finder_hists_run_data = [data.switch_finder_hists_run_data; zeros(1,1,run_params.detuning_array_number, run_params.number_repetitions, 360/input_params.analysis.clean_RTS_bin_width)]; 
    data.poisson_lifetime_state_1_array = [data.poisson_lifetime_state_1_array; zeros(1,1,run_params.detuning_array_number,1)];
    data.poisson_lifetime_state_2_array = [data.poisson_lifetime_state_2_array; zeros(1,1,run_params.detuning_array_number,1)];
    data.poisson_error_lifetime_1_in_us_array = [data.poisson_error_lifetime_1_in_us_array; zeros(1,1,run_params.detuning_array_number, 2)];
    data.poisson_error_lifetime_2_in_us_array = [data.poisson_error_lifetime_2_in_us_array; zeros(1,1,run_params.detuning_array_number, 2)];
end
    
%% loop initialization
detuning_point = run_params.detuning_point_start;
m_detuning = m_detuning_start;
res_freq = 5.9e9; % initialize well outside cCPT tunability so the VNA function has to find actual resonance.

while detuning_point < run_params.detuning_point_end + run_params.detuning_point_step
    m_repetition = 1;
    while m_repetition < run_params.number_repetitions + 1
        disp([13 10 13 10 13 10 13 10 13 10 13 10 13 10 ...
            'running m_detuning = ' num2str(m_detuning - m_detuning_start + 1) ' of ' num2str(run_params.detuning_expected_number) ...
            ', m_repetition = ' num2str(m_repetition) ' of ' num2str(run_params.number_repetitions)])
        %% record some input variables for this run
        input_params.pre_recorded_res_freq_values_struct(m_power, m_bias_point) = run_params.pre_recorded_struct;
        input_params.time_stamp{m_power, m_bias_point} = datestr(now, 'yymmdd_HHMMSS');
        input_params.ng_1_value(m_power, m_bias_point) = run_params.ng_1_value;
        input_params.flux_1_value(m_power, m_bias_point) = run_params.flux_1_value;
        input_params.input_power_value(m_power, m_bias_point) = run_params.input_power_value;
        input_params.AWG_power_value(m_power, m_bias_point) = run_params.awg.output_power;
        input_params.fridge_top_power_value(m_power, m_bias_point) = run_params.awg.output_power - input_params.additional_attenuation;
        input_params.awg.sequence{m_power, m_bias_point} = run_params.awg.sequence;
        input_params.detunings(m_power, m_bias_point, m_detuning) = detuning_point;
        input_params.run_number = input_params.run_number;
        input_params.run_order(m_power, m_bias_point, m_detuning) = input_params.run_number;
        data.detunings(m_power, m_bias_point, m_detuning) = detuning_point;
        data.peripheral.bias_point_offset_and_periods(m_power, m_bias_point) = bias_point;
        data.peripheral.gain_profile(m_power, m_bias_point) = gain_prof;
        data.peripheral.awg_output_power(m_power, m_bias_point) = run_params.awg.output_power;
        input_params.vna.input_power(m_power, m_bias_point) = run_params.input_power_value;
        input_params.analysis.moving_mean_average_time(m_power, m_bias_point, m_detuning) = run_params.analysis.moving_mean_average_time;
        input_params.analysis.min_gaussian_center_to_center_phase(m_power, m_bias_point, m_detuning) = run_params.analysis.min_gaussian_center_to_center_phase;

        if detuning_point == run_params.detuning_point_start && m_repetition == 1
            vna_data_acquisition = 1;
            res_freq_recorder = 1;
            bias_set_param = 1;
            % redefine (and generate) AWG sequence to load only if running first bias point for
            % this power
            run_params.awg.files_generation_param = 1;
        else
            vna_data_acquisition = 0;
            res_freq_recorder = 0;
            bias_set_param = 0;
            run_params.awg.files_generation_param = 0;
        end
        %% run the actual data collection code %%%%
        switching_rate_finder_single_cCPT_setting
        %%%%%%%%%%%%%%%%%%%%%%%%%%%

        data.drive_freq_GHz(m_power, m_bias_point, m_detuning) = detuning_point/1e3 + res_freq/1e9;
        data.recorded_res_freq_GHz(m_power, m_bias_point) = res_freq/1e9;

        %% clean the RTS data %%%%%%%%
        input_params.analysis.moving_mean_average_time(m_power, m_bias_point, m_detuning) = run_params.analysis.moving_mean_average_time;
        clean_RTS_data_struct
        input_params.analysis.bin_edges(m_power, m_bias_point, m_detuning, :) = run_params.analysis.bin_edges;
        %% Fit Poissonian
        if run_params.analysis.current_run_double_gaussian_existence == 1
            disp('fitting Poissonian')
            if temp.single_gaussian_fit_error > temp.double_gaussian_fit_error
                [temp.poisson_lifetime_1_us, temp.poisson_lifetime_2_us, temp.error_poisson_lifetime_1_us, temp.error_poisson_lifetime_2_us, ...
                    temp.poisson_theory_1, temp.poisson_theory_2, temp.switch_time_bin_centers_1, temp.hist_count_1, temp.switch_time_bin_centers_2, ...
                    temp.hist_count_2] = extract_poissonian_lifetimes(temp.clean_time_data, temp.clean_RTS_data, temp.gaussian_1_mean, temp.gaussian_2_mean, run_params.poissonian_fit_bin_number);
                run_params.Poisson_fig_plot_param = 1;
            else
                temp.poisson_lifetime_1_us = NaN;
                temp.poisson_lifetime_2_us = NaN;
                temp.error_poisson_lifetime_1_us = NaN;
                temp.error_poisson_lifetime_2_us = NaN;
                temp.poisson_theory_1 = zeros(1, run_params.poissonian_fit_bin_number);
                temp.poisson_theory_2 = zeros(1, run_params.poissonian_fit_bin_number);
                run_params.Poisson_fig_plot_param = 0;
                temp.switch_time_bin_centers_1 = zeros(1, run_params.poissonian_fit_bin_number);
                temp.hist_count_1 = zeros(1, run_params.poissonian_fit_bin_number);
                temp.switch_time_bin_centers_2 = zeros(1, run_params.poissonian_fit_bin_number);
                temp.hist_count_2 = zeros(1, run_params.poissonian_fit_bin_number);
            end

            input_params.analysis.poissonian_fit_bin_number(m_power, m_bias_point, m_detuning) = run_params.poissonian_fit_bin_number;
            analysis.Poissonian.lifetime_1(m_power, m_bias_point, m_detuning, m_repetition) = temp.poisson_lifetime_1_us;
            analysis.Poissonian.lifetime_2(m_power, m_bias_point, m_detuning, m_repetition) = temp.poisson_lifetime_2_us;
            analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_bias_point, m_detuning, m_repetition) = temp.error_poisson_lifetime_1_us;
            analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_bias_point, m_detuning, m_repetition) = temp.error_poisson_lifetime_2_us;
            analysis.Poissonian.poisson_theory_1(m_power, m_bias_point, m_detuning, m_repetition, :) = temp.poisson_theory_1;
            analysis.Poissonian.poisson_theory_2(m_power, m_bias_point, m_detuning, m_repetition, :) = temp.poisson_theory_2;
            analysis.Poissonian.switch_time_bin_centers_1(m_power, m_bias_point, m_detuning, m_repetition, :) = temp.switch_time_bin_centers_1;
            analysis.Poissonian.hist_count_1(m_power, m_bias_point, m_detuning, m_repetition, :) = temp.hist_count_1;
            analysis.Poissonian.switch_time_bin_centers_2(m_power, m_bias_point, m_detuning, m_repetition, :) = temp.switch_time_bin_centers_2;
            analysis.Poissonian.hist_count_2(m_power, m_bias_point, m_detuning, m_repetition, :) = temp.hist_count_2;
        end

        %% Plot Poissonian
        if run_params.analysis.current_run_double_gaussian_existence == 1
            if run_params.Poisson_fig_plot_param == 1
                if run_params.plot_visible == 1 
                    Poissonian_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
                elseif run_params.plot_visible == 0 
                    Poissonian_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
                end

                bar(temp.switch_time_bin_centers_1*1e6, log(temp.hist_count_1), 'r', 'FaceAlpha', 0.25, 'DisplayName', 'State 1 hist')
                hold on
                bar(temp.switch_time_bin_centers_1*1e6, log(temp.hist_count_2), 'b', 'FaceAlpha', 0.25, 'DisplayName', 'State 2 hist')
                plot(temp.switch_time_bin_centers_1*1e6, temp.poisson_theory_1, 'r', 'linewidth', 2, 'DisplayName', 'State 1 fit')
                plot(temp.switch_time_bin_centers_1*1e6, temp.poisson_theory_2, 'b', 'linewidth', 2, 'DisplayName', 'State 2 fit')
                xlabel('Switching time($\mu$s)', 'interpreter', 'latex')
                ylabel('log(Count)', 'interpreter', 'latex')
                title(['Poisson fit for P$_{\mathrm{in}}$ = ' num2str(run_params.input_power_value) 'dBm' 13 10 ...
                    '$n_g = $' num2str(run_params.ng_1_value) ', $\Phi_{\mathrm{ext}}$ = ' num2str(run_params.flux_1_value) '$\Phi_0$' 13 10 ...
                    '$\Delta$ = ' num2str(detuning_point) 'MHz' ], 'interpreter', 'latex')
                legend show

                if run_params.save_data_and_png_param == 1
                        save_file_name = [run_params.rts_fig_directory num2str(m_power) 'dBm_' num2str(m_bias_point) '_' num2str(m_repetition)...
                            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_detuning_' num2str(detuning_point) 'MHz_poisson_fit.png'];
                        saveas(Poissonian_figure, save_file_name)
                        save_file_name = [run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' num2str(m_bias_point) '_' num2str(m_repetition)...
                            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_detuning_' num2str(detuning_point) 'MHz_poisson_fit.fig'];
                        saveas(Poissonian_figure, save_file_name)
                end
                clear Poissonian_figure ...
                      save_file_name
            end
            clear bias_point_struct ...
                  temp
            close all
        end
        m_repetition = m_repetition + 1;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    detuning_point = detuning_point + run_params.detuning_point_step;
    m_detuning = m_detuning + 1;
end
clear res_freq 
%% Plot lifetime curves
if run_params.plot_visible == 1 
    Lifetime_detuning_plots = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
elseif run_params.plot_visible == 0 
    Lifetime_detuning_plots = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
end

errorbar(mean(squeeze(data.detunings(m_power, m_bias_point, m_detuning_start:m_detuning_start + run_params.detuning_expected_number - 1, :)), 2), ...
    mean(squeeze(analysis.Poissonian.lifetime_1(m_power, m_bias_point, m_detuning_start:m_detuning_start + run_params.detuning_expected_number - 1, :)), 2), ...
    mean(squeeze(analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_bias_point, m_detuning_start:m_detuning_start + run_params.detuning_expected_number - 1, :)), 2), ...
    mean(squeeze(analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_bias_point, m_detuning_start:m_detuning_start + run_params.detuning_expected_number - 1, :)), 2), ...
    squeeze(analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_bias_point)*ones(run_params.detuning_expected_number, 1))/1e6, ...
    squeeze(analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_bias_point)*ones(run_params.detuning_expected_number, 1))/1e6, ...
    'rx-', 'Linewidth', 3, 'DisplayName', 'State 1 lifetimes')
hold on
errorbar(mean(squeeze(data.detunings(m_power, m_bias_point, m_detuning_start:m_detuning_start + run_params.detuning_expected_number - 1, :)), 2), ...
    mean(squeeze(analysis.Poissonian.lifetime_2(m_power, m_bias_point, m_detuning_start:m_detuning_start + run_params.detuning_expected_number - 1, :)), 2), ...
    mean(squeeze(analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_bias_point,  m_detuning_start:m_detuning_start + run_params.detuning_expected_number - 1, :)), 2), ...
    mean(squeeze(analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_bias_point,  m_detuning_start:m_detuning_start + run_params.detuning_expected_number - 1, :)), 2), ...
    squeeze(analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_bias_point)*ones(run_params.detuning_expected_number, 1))/1e6, ...
    squeeze(analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_bias_point)*ones(run_params.detuning_expected_number, 1))/1e6, ...
    'bx-', 'Linewidth', 3, 'DisplayName', 'State 2 lifetimes')

xlabel('$\Delta$ (MHz)', 'interpreter', 'latex')
ylabel('Time ($\mu$s)', 'interpreter', 'latex')
title(['Lifetimes for fit for P$_{\mathrm{in}}$ = ' num2str(run_params.input_power_value) 'dBm' 13 10 ...
    '$n_g = $' num2str(run_params.ng_1_value) ', $\Phi_{\mathrm{ext}}$ = ' num2str(run_params.flux_1_value) '$Phi_0$'], 'interpreter', 'latex')
legend show

if run_params.save_data_and_png_param == 1
        save_file_name = [run_params.fig_directory num2str(m_power) 'dBm_' num2str(m_bias_point) ...
            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_lifetimes.png'];
        saveas(Lifetime_detuning_plots, save_file_name)
        save_file_name = [run_params.fig_directory num2str(m_power) '_' num2str(m_bias_point) ...
            '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_lifetimes.fig'];
        saveas(Lifetime_detuning_plots, save_file_name)
end
clear Lifetime_detuning_plots ...
      save_file_name 
close all
switch_vna_measurement
vna_set_power(vna, -65, 1)
vna_turn_output_on(vna)
clear_instruments
if run_params.save_data_and_png_param == 1
    save([run_params.data_directory '\' run_params.file_name], '-regexp', '^(?!(run_params)$).')   
end
clear run_params
%% Function extract Poissonian lifetimes
function [lifetime_1_us, lifetime_2_us, std_exp_fit_state_1, std_exp_fit_state_2, theory_values_state_1, theory_values_state_2, time_bin_centers_state_1, lifetime_state_1_hist_data, ...
    time_bin_centers_state_2,  lifetime_state_2_hist_data] =  extract_poissonian_lifetimes(clean_time_data, clean_amp_data, gaussian_1_mean, gaussian_2_mean,bin_number)

    if ~exist('bin_number', 'var')
        bin_number = 25;
    end
    
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
    [lifetime_state_1_hist_data, time_bin_centers_state_1] = hist(lifetime_state_1_array, bin_number );
    [lifetime_state_2_hist_data, time_bin_centers_state_2] = hist(lifetime_state_2_array, bin_number );
%     
%     time_bin_centers_state_1(lifetime_state_1_hist_data < 5) = NaN;
%     lifetime_state_1_hist_data(lifetime_state_1_hist_data < 5) = NaN;
%     time_bin_centers_state_2(lifetime_state_2_hist_data < 5) = NaN;
%     lifetime_state_2_hist_data(lifetime_state_2_hist_data < 5) = NaN;
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
%     figure
%     bar(time_bin_centers_state_1*1e6, log(lifetime_state_1_hist_data))
%     hold on
%     plot(time_bin_centers_state_1*1e6, theory_values_state_1)
%     bar(time_bin_centers_state_2*1e6, log(lifetime_state_2_hist_data))
%     plot(time_bin_centers_state_2*1e6, theory_values_state_2)
%     xlabel('Switching time (\mus)')
%     ylabel('log(count)')
        
end