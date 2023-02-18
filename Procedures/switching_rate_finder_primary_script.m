%% input params start
%%%% ensure that a 'bias_point_struct' is initialized in the workspace which
%%%% contains :
%%%% flux_zero_voltage, flux_period, gate_offset, gate_period,
%%%% flux_center_freq_mean, gate_values_gate and res_freqs_gate
%%%% and a 'gain_profile_struct' that contains :
%%%% freq, amp, phase
run_params.concatenate_runs = 1; % 0/1 - decides whether this run is going to concatenate data to an existing file
run_params.initialize_or_load  = 1; % 0 - initialize, 1 - load old data. run will pause after loading old data. if it doesn't, run not loaded.
run_params.redo_previously_saved_run = 1; % if this is the same as the previous run, redone for some reason, this will make sure it is overwritten.
run_params.analysis_during_acquisition = 0; % to analyse RTS and Poissonian hist during acquisition, or analyse separately.
run_params.analysis.save_RTS_PSD_extended_data = 0; % to save PSD and RTS data for a short period of time set later. This is only if analyzed during acquisition
if run_params.concatenate_runs
    run_params.data_directory = [cd '\data'];
    run_params.file_name = 'switching_finder_comprehensive_data.mat';
end
run_params.save_data_and_png_param = 1; % 0/1 - decides whether to save data and figs or not. 
run_params.save_fig_file_param = 0; % fig file for actual time trace of phase. usually very large for ms data at high sampling
run_params.plot_visible = 0;
run_params.set_with_pre_recorded = 1; %%% verify set res freq with one saved in a pre recorded data set.
input_params.ng_1_value_list = 0: 0.1:0.7;
input_params.flux_1_value_list = 0: 0.04 : .24;
input_params.input_power_value_list = -130 : 2 : -114;
run_params.m_flux = 7;
run_params.m_gate = 1;
run_params.number_repetitions = 5;
for m_power = 1 : 1
%%%% uncomment this for a long run sweeping bias points automatically
%     for m_flux = 1: length(input_params.flux_1_value_list)
%         for m_gate = 1: length(input_params.ng_1_value_list)
%%%% uncomment this for a single bias  point at a time.
    for m_flux = run_params.m_flux : run_params.m_flux
        for m_gate = run_params.m_gate : run_params.m_gate
            m_bias_point = (m_flux - 1)*length(input_params.ng_1_value_list) + m_gate;
            run_params.ng_1_value = input_params.ng_1_value_list(m_gate);
            run_params.flux_1_value = input_params.flux_1_value_list(m_flux);
            run_params.input_power_value = input_params.input_power_value_list(m_power); % power at the sample, adjusted using fridge attenuation and additional attenuation params.

            run_params.detuning_point_start = -15; % in MHz % do not exceed +/- 50MHz
            run_params.detuning_point_end = -1; % in MHz. 
            run_params.detuning_point_step = 0.5; % in MHz. % typically set to 0.5MHz 
            m_detuning_start = (run_params.detuning_point_start + 50)/0.5 + 1;
            %%% deliberately make expected detuning number large so dont have to worry
            %%% about variation in array size. each array point corresponds to -50MHz to
            %%% +50, steps of 0.5
            input_params.detuning_array_number = 2 * 50 / 0.5 + 1;
            run_params.detunings_expected_number = abs((run_params.detuning_point_start - run_params.detuning_point_end)/ run_params.detuning_point_step) + 1;  
            run_params.save_raw_data_frequency = 10; %%% saves raw data for every so many detunings.

            %%%%% load gain profile and bias point
            if ~exist('gain_prof', 'var')
                disp('enter directory where gain_prof_struct.mat is saved')
                load_directory = 'C:\Users\Sisira\Desktop\feb_16th_2022';
%                load_directory = uigetdir('enter directory where gain_prof_struct.mat is saved');
               load([load_directory '\gain_prof_struct.mat'], 'gain_prof')
               clear load_directory
            end

            if ~exist('bias_point', 'var') 
               disp('enter directory where bias_point_struct.mat is saved')
%                load_directory = 'C:\Users\rimberg-lab\Desktop\feb_16th_2022';
                load_directory = 'C:\Users\Sisira\Desktop\feb_16th_2022';
%                load_directory = uigetdir;
               load([load_directory '\bias_point_struct.mat'], 'bias_point')
               clear load_directory
            end

            if run_params.set_with_pre_recorded && ~isfield(run_params, 'pre_recorded_struct')
                disp('enter directory where pre_recorded_values.mat is saved')
%                load_directory = uigetdir;
               load_directory = '\\dartfs-hpc\rc\lab\R\RimbergA\cCPT_NR_project\Bhar_measurements\2022_December_Jules_sample\q_circle_freq_flucs_scan\twpa_pump_setting_1\d221231_004136_q_circles';
               load([load_directory '\pre_recorded_values.mat'], 'pre_recorded')
               run_params.pre_recorded_struct = pre_recorded;
               clear load_directory ...
                     pre_recorded
            end
            %%%%%%%%%%

            %%% generate some file names
            date = datetime('now','format', 'yyyy-MM-dd HH:mm:ss Z');
            date = char(date);
            run_params.awg_switching_directory_name = 'sw';
            run_params.awg_directory = ['/' run_params.awg_switching_directory_name '/' date(1:7)];
            clear date;
            if run_params.concatenate_runs
                run_params.fig_directory = [cd '\plots\'];
                run_params.rts_fig_directory = [cd '\plots\rts\'];
            end

            if run_params.concatenate_runs && run_params.initialize_or_load 
                load([run_params.data_directory '\' run_params.file_name], '-regexp', '^(?!(run_params|bias_point|gain_prof)$).')  
                if m_bias_point == 1
                    disp(['loaded ' run_params.file_name '. Continue?'])
                    pause
                end
            elseif ~run_params.concatenate_runs
                input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
                sign_of_ng = num2str(sign(run_params.ng_1_value));
                sign_of_ng = sign_of_ng(1);
                sign_of_flux = num2str(sign(run_params.flux_1_value));
                sign_of_flux = sign_of_flux(1);
                run_params.root_directory = ['/d' input_params.file_name_time_stamp '_ng_' sign_of_ng num2str(fix(run_params.ng_1_value)) 'p' ...
                    num2str(mod(abs(run_params.ng_1_value), 1)) '_flux_' sign_of_flux num2str(fix(run_params.flux_1_value)) 'p' ...
                    num2str(mod(abs(run_params.flux_1_value), 1))];
                mkdir([cd run_params.root_directory])
                if ~run_params.analysis_during_acquisition
                    run_params.file_name = 'unanalyzed_data.mat';
                else
                    run_params.file_name = 'analyzed_data.mat';
                end
                run_params.fig_directory = [cd run_params.root_directory '\plots\'];
                run_params.rts_fig_directory = [cd run_params.root_directory '\plots\rts\'];
                run_params.data_directory = [cd run_params.root_directory '\data\'];
                clear sign_of_ng ...
                      sign_of_flux
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%
            if ~exist('data','var')
                data.dummy = [];
            end
            if ~isfield(data, 'done_parameter') 
                data.done_parameter = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                rmfield(data, 'dummy');
            end        

            if ~isfield(input_params, 'run_number')
                input_params.run_number = 0;
            elseif run_params.redo_previously_saved_run 
                input_params.run_number = input('what is the desired run number - 1?');
%                 input_params.run_number = input_params.run_number - 1;
            end 
            input_params.run_number = input_params.run_number + 1;
            %% Attenuation values
            input_params.fridge_attenuation = 85.8;
            input_params.additional_attenuation = 31.97; % dB. big fridge setup as of 2/11/2023. see notes_feb_11th_2023.txt in folder below
            %%%%\\dartfs-hpc\rc\lab\R\RimbergA\cCPT_NR_project\Bhar_measurements\2022_December_Jules_sample\AWG_input_attenuation_calibration
            data.fridge_attenuation_used(m_power, m_flux, m_gate) = input_params.fridge_attenuation;
            data.awg_additional_attenuation_used(m_power, m_flux, m_gate) = input_params.additional_attenuation;
            %% Analysis params - if analysis being done 
            input_params.if_freq = 21e6; % freq to which output signal is mixed down
            if run_params.analysis_during_acquisition  % only if analyzing during run. if not, these params set in post run analysis clean RTS file
                input_params.analysis.clean_RTS_bin_width = 6; % degs - phase histogramming bin size
                run_params.analysis.moving_mean_average_time = 3; % in us
                run_params.analysis.number_iterations = 5; % number of iterations for the clean RTS algorithm
                input_params.analysis.phase_outlier_cutoff = 70; % in degs, this is the phase above and below the mean phase, over which the phase is classified as an outlier (after moving mean)
                run_params.analysis.min_gaussian_center_to_center_phase = 15; % in degs, this is the minimum distance between gaussian centers that the double gaussian fit accepts
                run_params.analysis.max_gaussian_center_to_center_phase = 60; % in degs
                input_params.analysis.min_gaussian_count = 1500;
                input_params.minimum_number_switches = 100;
                run_params.analysis.double_gaussian_fit_sigma_guess = 15; % degs
                run_params.analysis.plotting_time_for_RTS = 150e-6;
                input_params.time_length_of_RTS_raw_data_to_store = 50e-6; % in s
                input_params.start_time_of_RTS_raw_data_to_store = 5.1e-3; % in s
                run_params.poissonian_fit_bin_number = 25;
                run_params.poissonian_lifetime_repetitions_mode = 'separate_and_together'; % 'separate' or 'averaged', 'histogrammed_together', 'separate_and_together'
            end
            %% VNA parameter settings
            input_params.vna.average_number = 50;
            input_params.vna.IF_BW = 1e3;
            input_params.vna.number_points = 201;
            run_params.vna.power = run_params.input_power_value + input_params.fridge_attenuation;
            input_params.vna.rough_center = 5.76e9;
            input_params.vna.rough_span = 250e6;
            input_params.vna.rough_IF_BW = 10e3;
            input_params.vna.zoom_scan_span = 15e6;
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
            %% create folders
            if run_params.save_data_and_png_param == 1
                mkdir(run_params.data_directory)
                mkdir(run_params.fig_directory)
                mkdir([run_params.fig_directory 'fig_files'])
                mkdir(run_params.rts_fig_directory)
                mkdir([run_params.rts_fig_directory 'fig_files'])
            end
            % end
            %%% input params end            
            %% prepare run start
            tic;
            %%%%%%%%%%
            disp(['input power number = ' num2str(m_power) ' of ' num2str(length(input_params.input_power_value_list)) 13 10 ...
                'input power = ' num2str(run_params.input_power_value) 'dBm' 13 10 ...
                'bias point number = ' num2str(m_bias_point) 13 10 ...
                'flux point number = ' num2str(m_flux) ' of ' num2str(length(input_params.flux_1_value_list)) 13 10 ...
                'gate point number = ' num2str(m_gate) ' of ' num2str(length(input_params.ng_1_value_list)) 13 10 ...
                'bias point is ng = ' num2str(run_params.ng_1_value) ', flux = ' num2str(run_params.flux_1_value) 13 10 ...
                'correct bias point number and bias point calibration?'])
    %         pause
            if (~run_params.redo_previously_saved_run && data.done_parameter(m_power, m_flux, m_gate)) 
                disp('overwriting previously acquired data point. If deliberate, reset "run_params.redo_previously_saved_run" param and rerun')
                return
            end
            %% initialize arrays 
            if ~exist('data', 'var') && run_params.concatenate_runs
                %% arrays for VNA data and analysis single photon
                data.vna.single_photon.rough.freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.rough.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.rough.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.rough.real = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.rough.imag = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);

                data.vna.single_photon.fine.freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.fine.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.fine.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.fine.real = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.fine.imag = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                
                %%% for final arrays
                data.vna.single_photon.final.rough.freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.final.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.final.rough.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.final.rough.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.final.rough_resonance = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.final.res_freq_shift_during_run = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);

                data.vna.single_photon.final.fine.freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.final.fine.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.final.fine.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                %%%%%%%%%%%%

                analysis.vna.single_photon.fits_no_flucs.real = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_no_flucs.imag = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_no_flucs.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_no_flucs.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.single_photon.fits_flucs_no_angle.real = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_no_angle.imag = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_no_angle.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_no_angle.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.single_photon.fits_flucs_and_angle.real = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_and_angle.imag = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_and_angle.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_and_angle.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.single_photon.interp_gain_amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.interp_gain_phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.subtracted_amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.subtracted_phase  = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.single_photon.fits_no_flucs.gamma_ext = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_no_flucs.gamma_int = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_no_flucs.res_freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_no_flucs.goodness_fit = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));

                analysis.vna.single_photon.fits_flucs_no_angle.gamma_ext = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_no_angle.gamma_int = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_no_angle.res_freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_no_angle.sigma = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_no_angle.goodness_fit = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));

                analysis.vna.single_photon.fits_flucs_and_angle.gamma_ext = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_and_angle.gamma_int = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_and_angle.res_freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_and_angle.sigma = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_and_angle.angle = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list)); 
                analysis.vna.single_photon.fits_flucs_and_angle.goodness_fit = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list)); 
                %% arrays for vna data and analysis actual power
                data.vna.actual_power.rough.freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.actual_power.rough.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.actual_power.rough.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.actual_power.rough.real = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.actual_power.rough.imag = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);

                data.vna.actual_power.fine.freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.actual_power.fine.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.actual_power.fine.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.actual_power.fine.real = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.actual_power.fine.imag = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.actual_power.fits_no_flucs.real = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.fits_no_flucs.imag = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.fits_no_flucs.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.fits_no_flucs.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.actual_power.fits_flucs_no_angle.real = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.fits_flucs_no_angle.imag = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.fits_flucs_no_angle.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.fits_flucs_no_angle.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.actual_power.fits_flucs_and_angle.real = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.fits_flucs_and_angle.imag = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.fits_flucs_and_angle.amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.fits_flucs_and_angle.phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.actual_power.interp_gain_amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.interp_gain_phase = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.subtracted_amp = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.actual_power.subtracted_phase  = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.actual_power.fits_no_flucs.gamma_ext = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_no_flucs.gamma_int = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_no_flucs.res_freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_no_flucs.goodness_fit = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));

                analysis.vna.actual_power.fits_flucs_no_angle.gamma_ext = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_flucs_no_angle.gamma_int = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_flucs_no_angle.res_freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_flucs_no_angle.sigma = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_flucs_no_angle.goodness_fit = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));

                analysis.vna.actual_power.fits_flucs_and_angle.gamma_ext = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_flucs_and_angle.gamma_int = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_flucs_and_angle.res_freq = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_flucs_and_angle.sigma = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.actual_power.fits_flucs_and_angle.angle = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list)); 
                analysis.vna.actual_power.fits_flucs_and_angle.goodness_fit = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list)); 
                %% other data arrays
            data.detunings = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.detuning_array_number, run_params.number_repetitions);
            data.recorded_res_freq_GHz = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.detuning_array_number, run_params.number_repetitions);
            data.peripheral.awg_output_power = zeros(length(input_params.input_power_value_list), length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.detuning_array_number, run_params.number_repetitions);
            end
            %% detuning and repetition loop initialization
            detuning_point = run_params.detuning_point_start;
            m_detuning = m_detuning_start;
            res_freq = 5.9e9; % initialize well outside cCPT tunability so the VNA function has to find actual resonance.

            while detuning_point < run_params.detuning_point_end + run_params.detuning_point_step
                disp([13 10 13 10 13 10 13 10 ...
                    'running m_detuning = ' num2str(m_detuning - m_detuning_start + 1) ' of ' num2str(run_params.detunings_expected_number * run_params.detuning_point_step/0.5) ...
                    ', number repetitions = ' num2str(run_params.number_repetitions)])
                elapsed_time = toc;
                disp(['Elapsed time since start of run : ' num2str(floor(elapsed_time/3600)) 'hrs, ' num2str(floor(mod(elapsed_time, 3600)/60)) 'mins, ' ...
                    num2str(mod(mod(elapsed_time, 3600),60)) 'seconds'])
                %% record some input variables for this run
                if run_params.set_with_pre_recorded
                    data.pre_recorded_res_freq_values_struct(m_power, m_flux, m_gate) = run_params.pre_recorded_struct;
                end
                data.time_stamp{m_power, m_flux, m_gate} = datestr(now, 'yymmdd_HHMMSS');
                data.elapsed_time_since_loop_start(m_power, m_flux, m_gate, m_detuning) = elapsed_time;
                data.ng_1_value_by_bias_point(m_power, m_bias_point) = run_params.ng_1_value;
                data.flux_1_value_by_bias_point(m_power, m_bias_point) = run_params.flux_1_value;
                data.ng_1_value_by_gate_flux(m_power, m_bias_point) = run_params.ng_1_value;
                data.flux_1_value_by_gate_flux(m_power, m_bias_point) = run_params.flux_1_value;
                data.input_power_value(m_power, m_flux, m_gate) = run_params.input_power_value;
                data.AWG_power_value(m_power, m_flux, m_gate) = run_params.awg.output_power;
                data.fridge_top_power_value(m_power, m_flux, m_gate) = run_params.awg.output_power - input_params.additional_attenuation;
                data.awg.sequence{m_power, m_flux, m_gate} = run_params.awg.sequence;
                input_params.detunings(m_power, m_flux, m_gate, m_detuning) = detuning_point;
                data.detunings(m_power, m_flux, m_gate, m_detuning) = detuning_point;
                data.run_number(m_power, m_flux, m_gate, m_detuning) = input_params.run_number;
                input_params.run_order(m_power, m_flux, m_gate, m_detuning) = input_params.run_number;
                data.run_order(m_power, m_flux, m_gate, m_detuning) = input_params.run_number;
                data.detunings(m_power, m_flux, m_gate, m_detuning, 1:run_params.number_repetitions) = detuning_point;
                data.peripheral.bias_point_offset_and_periods(m_power, m_flux, m_gate) = bias_point;
                data.peripheral.gain_profile(m_power, m_flux, m_gate) = gain_prof;
                data.peripheral.awg_output_power(m_power, m_flux, m_gate) = run_params.awg.output_power;
                data.repetition_number(m_power, m_flux, m_gate, m_detuning) = run_params.number_repetitions;
                input_params.vna.input_power(m_power, m_flux, m_gate) = run_params.input_power_value;
                if run_params.analysis_during_acquisition
                    input_params.analysis.moving_mean_average_time(m_power, m_flux, m_gate, m_detuning) = run_params.analysis.moving_mean_average_time;
                    input_params.analysis.min_gaussian_center_to_center_phase(m_power, m_flux, m_gate, m_detuning) = run_params.analysis.min_gaussian_center_to_center_phase;
                end
                %% decide whether to collect res freq, generate sequence, set bias and so on
                if detuning_point == run_params.detuning_point_start
                    vna_data_acquisition = 0;
                    res_freq_recorder = 1;
                    bias_set_param = 0;
                    % redefine (and generate) AWG sequence to load only if running
                    % first detuning for this bias point and this power
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
                %% record some other data variables
                data.drive_freq_GHz(m_power, m_flux, m_gate, m_detuning) = detuning_point/1e3 + res_freq/1e9;
                data.recorded_res_freq_GHz(m_power, m_flux, m_gate) = res_freq/1e9;
                data.kerr_MHz(m_power, m_flux, m_gate) = kerr_MHz_expected_for_Jules_sample(run_params.ng_1_value, run_params.flux_1_value);
                %% clean the RTS data %%%%%%%%
                if run_params.analysis_during_acquisition
                    data.poissonian_lifetime_repetitions_mode{m_power, m_flux, m_gate, m_detuning} = run_params.poissonian_lifetime_repetitions_mode;
                    input_params.analysis.moving_mean_average_time(m_power, m_flux, m_gate, m_detuning) = run_params.analysis.moving_mean_average_time;
                    for m_repetition = 1 : run_params.number_repetitions
                        clean_RTS_data_struct
                        input_params.analysis.bin_edges(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = run_params.analysis.bin_edges;
                        %% Fit Poissonian
                        analysis.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition) = 0; %%% initiate fit success at 0.
                        
                        %%%%% if conditions to only fit poissonian if bistability exists.
                        if run_params.analysis.current_run_bistability_existence == 1
                            disp('bistability detected, fitting Poissonian')
                            %%%% if conditions to analyze according to chosen poisson fitting method. averaged and separate are straight forward. 
                            %%%% histogrammed together and separate_and_together are a little involved to cover all failure modes
                            
                            if strcmp(run_params.poissonian_lifetime_repetitions_mode, 'separate') || ...
                                    strcmp(run_params.poissonian_lifetime_repetitions_mode, 'averaged') || ...
                                    (strcmp(run_params.poissonian_lifetime_repetitions_mode, 'histogrammed_together') && m_repetition == 1) || ...
                                    (strcmp(run_params.poissonian_lifetime_repetitions_mode, 'histogrammed_together') && m_repetition > 1 && ...
                                    analysis.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition - 1) == 0)
                                [temp.poisson_lifetime_1_us, temp.poisson_lifetime_2_us, temp.error_poisson_lifetime_1_us, temp.error_poisson_lifetime_2_us, ...
                                    temp.poisson_theory_1, temp.poisson_theory_2, temp.switch_time_bin_centers_1, temp.hist_count_1, temp.switch_time_bin_centers_2, ...
                                    temp.hist_count_2, temp.fit_success, temp.fit_flag] = extract_poissonian_lifetimes(temp.clean_time_data(:), temp.clean_RTS_data(:), temp.gaussian_1_mean, ...
                                    temp.gaussian_2_mean, run_params.poissonian_fit_bin_number);
                                if ~temp.fit_success
                                   analysis.sign_of_bistability(m_power, m_flux, m_gate, m_detuning, m_repetition) = 0;
                                end
                            elseif strcmp(run_params.poissonian_lifetime_repetitions_mode, 'histogrammed_together') && m_repetition > 1
                                [temp.poisson_lifetime_1_us, temp.poisson_lifetime_2_us, temp.error_poisson_lifetime_1_us, temp.error_poisson_lifetime_2_us, ...
                                    temp.poisson_theory_1, temp.poisson_theory_2, temp.switch_time_bin_centers_1, temp.hist_count_1, temp.switch_time_bin_centers_2, ...
                                    temp.hist_count_2, temp.fit_success, temp.fit_flag] = extract_poissonian_lifetimes(temp.clean_time_data(:), temp.clean_RTS_data(:), temp.gaussian_1_mean, ...
                                    temp.gaussian_2_mean, input_params.minimum_number_switches, [], ...
                                    squeeze(analysis.Poissonian.hist_count_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)),  ...
                                    squeeze(analysis.Poissonian.hist_count_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)), ...
                                    squeeze(analysis.Poissonian.switch_time_bin_centers_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)), ...
                                    squeeze(analysis.Poissonian.switch_time_bin_centers_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)));
                                if ~temp.fit_success
                                   analysis.sign_of_bistability(m_power, m_flux, m_gate, m_detuning, m_repetition) = 0;
                                end
                            end
                            
                            %%%% for separate and together - first part for separate, same as usual, second part for histogramming together
                            if strcmp(run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together') 
                                [temp.poisson_lifetime_1_us, temp.poisson_lifetime_2_us, temp.error_poisson_lifetime_1_us, temp.error_poisson_lifetime_2_us, ...
                                    temp.poisson_theory_1, temp.poisson_theory_2, temp.switch_time_bin_centers_1, temp.hist_count_1, temp.switch_time_bin_centers_2, ...
                                    temp.hist_count_2, temp.fit_success, temp.fit_flag] = extract_poissonian_lifetimes(temp.clean_time_data, temp.clean_RTS_data, temp.gaussian_1_mean, ...
                                    temp.gaussian_2_mean, input_params.minimum_number_switches, run_params.poissonian_fit_bin_number);
                                if ~temp.fit_success
                                   analysis.sign_of_bistability(m_power, m_flux, m_gate, m_detuning, m_repetition) = 0;
                                end
                                if m_repetition == 1 || (m_repetition > 1 && ...
                                            analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition - 1) == 0 && ...
                                            ~contains(analysis.hist_together.Poissonian.flag{m_power, m_flux, m_gate, m_detuning, m_repetition - 1}, 'fewer than') && ...
                                            ~contains(analysis.hist_together.Poissonian.flag{m_power, m_flux, m_gate, m_detuning, m_repetition - 1}, 'at least'))
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
                                    temp.hist_together.fit_flag = temp.fit_flag;
                                elseif m_repetition > 1                     
                                    [temp.hist_together.poisson_lifetime_1_us, temp.hist_together.poisson_lifetime_2_us, temp.hist_together.error_poisson_lifetime_1_us, ...
                                        temp.hist_together.error_poisson_lifetime_2_us, temp.hist_together.poisson_theory_1, temp.hist_together.poisson_theory_2, ...
                                        temp.hist_together.switch_time_bin_centers_1, temp.hist_together.hist_count_1, temp.hist_together.switch_time_bin_centers_2, ...
                                        temp.hist_together.hist_count_2, temp.hist_together.fit_success, temp.hist_together.fit_flag] = extract_poissonian_lifetimes(temp.clean_time_data, ...
                                        temp.clean_RTS_data, temp.gaussian_1_mean, temp.gaussian_2_mean, input_params.minimum_number_switches, [], ...
                                        squeeze(analysis.hist_together.Poissonian.hist_count_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)),  ...
                                        squeeze(analysis.hist_together.Poissonian.hist_count_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)), ...
                                        squeeze(analysis.hist_together.Poissonian.switch_time_bin_centers_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)), ...
                                        squeeze(analysis.hist_together.Poissonian.switch_time_bin_centers_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :)));
                                end
                            end
                        else
                            temp.poisson_lifetime_1_us = NaN;
                            temp.poisson_lifetime_2_us = NaN;
                            temp.error_poisson_lifetime_1_us = NaN;
                            temp.error_poisson_lifetime_2_us = NaN;
                            temp.poisson_theory_1 = zeros(1, run_params.poissonian_fit_bin_number);
                            temp.poisson_theory_2 = zeros(1, run_params.poissonian_fit_bin_number);
                            temp.switch_time_bin_centers_1 = zeros(1, run_params.poissonian_fit_bin_number);
                            temp.hist_count_1 = zeros(1, run_params.poissonian_fit_bin_number);
                            temp.switch_time_bin_centers_2 = zeros(1, run_params.poissonian_fit_bin_number);
                            temp.hist_count_2 = zeros(1, run_params.poissonian_fit_bin_number);
                            temp.fit_success = 0;
                            temp.fit_flag = 'lack of bistability from Gaussians';
                            
                            if strcmp(run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together') && (m_repetition == 1 || ...
                                    (m_repetition > 1 && sum(squeeze(analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, :))) == 0))
                                temp.hist_together.poisson_lifetime_1_us = NaN;
                                temp.hist_together.poisson_lifetime_2_us = NaN;
                                temp.hist_together.error_poisson_lifetime_1_us = NaN;
                                temp.hist_together.error_poisson_lifetime_2_us = NaN;
                                temp.hist_together.poisson_theory_1 = zeros(1, run_params.poissonian_fit_bin_number);
                                temp.hist_together.poisson_theory_2 = zeros(1, run_params.poissonian_fit_bin_number);
                                temp.hist_together.switch_time_bin_centers_1 = zeros(1, run_params.poissonian_fit_bin_number);
                                temp.hist_together.hist_count_1 = zeros(1, run_params.poissonian_fit_bin_number);
                                temp.hist_together.switch_time_bin_centers_2 = zeros(1, run_params.poissonian_fit_bin_number);
                                temp.hist_together.hist_count_2 = zeros(1, run_params.poissonian_fit_bin_number);
                                temp.hist_together.fit_success = 0;
                                temp.hist_together.fit_flag = 'lack of bistability from Gaussians';
                            elseif (m_repetition > 1 && sum(squeeze(analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, :))) ~= 0)
                                temp.hist_together.poisson_lifetime_1_us = squeeze(analysis.hist_together.Poissonian.poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition - 1));
                                temp.hist_together.poisson_lifetime_2_us = squeeze(analysis.hist_together.Poissonian.poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning, m_repetition - 1));
                                temp.hist_together.error_poisson_lifetime_1_us = squeeze(analysis.hist_together.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition - 1));
                                temp.hist_together.error_poisson_lifetime_2_us = squeeze(analysis.hist_together.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition - 1));
                                temp.hist_together.poisson_theory_1 = squeeze(analysis.hist_together.Poissonian.poisson_theory_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :));
                                temp.hist_together.poisson_theory_2 =  squeeze(analysis.hist_together.Poissonian.poisson_theory_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :));
                                temp.hist_together.switch_time_bin_centers_1 = squeeze(analysis.hist_together.Poissonian.switch_time_bin_centers_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :));
                                temp.hist_together.hist_count_1 = squeeze(analysis.hist_together.Poissonian.hist_count_1(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :));
                                temp.hist_together.switch_time_bin_centers_2 = squeeze(analysis.hist_together.Poissonian.switch_time_bin_centers_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :));
                                temp.hist_together.hist_count_2 = squeeze(analysis.hist_together.Poissonian.hist_count_2(m_power, m_flux, m_gate, m_detuning, m_repetition - 1, :));
                                temp.hist_together.fit_success = squeeze(analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition - 1));
                                temp.hist_together.fit_flag = 'lack of bistability from Gaussians';
                            end
                        end
                        run_params.Poisson_fig_plot_param = temp.fit_success;
                        
                        input_params.analysis.current_run_bistability_existence (m_power, m_flux, m_gate, m_repetition) = run_params.analysis.current_run_bistability_existence;
                        input_params.analysis.poissonian_fit_bin_number(m_power, m_flux, m_gate, m_detuning) = run_params.poissonian_fit_bin_number;
                        analysis.Poissonian.lifetime_1(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.poisson_lifetime_1_us;
                        analysis.Poissonian.lifetime_2(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.poisson_lifetime_2_us;
                        analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.error_poisson_lifetime_1_us;
                        analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.error_poisson_lifetime_2_us;
                        analysis.Poissonian.switch_time_bin_centers_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.switch_time_bin_centers_1;
                        analysis.Poissonian.switch_time_bin_centers_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.switch_time_bin_centers_2;
                        analysis.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.fit_success;
                        analysis.Poissonian.flag{m_power, m_flux, m_gate, m_detuning, m_repetition} = temp.fit_flag;


                        analysis.Poissonian.hist_count_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_count_1(:);
                        analysis.Poissonian.hist_count_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_count_2(:);

                        analysis.Poissonian.poisson_theory_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.poisson_theory_1(:);
                        analysis.Poissonian.poisson_theory_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.poisson_theory_2(:);
                        analysis.Poissonian.flag{m_power, m_flux, m_gate, m_detuning, m_repetition} = temp.fit_flag;
                        
                        if strcmp(run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together') 
                            analysis.hist_together.Poissonian.poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.hist_together.poisson_lifetime_1_us;
                            analysis.hist_together.Poissonian.poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.hist_together.poisson_lifetime_2_us;
                            analysis.hist_together.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.hist_together.error_poisson_lifetime_1_us;
                            analysis.hist_together.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.hist_together.error_poisson_lifetime_2_us;
                            analysis.hist_together.Poissonian.switch_time_bin_centers_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.switch_time_bin_centers_1;
                            analysis.hist_together.Poissonian.switch_time_bin_centers_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.switch_time_bin_centers_2;
                            
                            analysis.hist_together.Poissonian.hist_count_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.hist_count_1(:);

                            analysis.hist_together.Poissonian.hist_count_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.hist_count_2(:);

                            analysis.hist_together.Poissonian.poisson_theory_1(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.poisson_theory_1(:);

                            analysis.hist_together.Poissonian.poisson_theory_2(m_power, m_flux, m_gate, m_detuning, m_repetition, :) = temp.hist_together.poisson_theory_2(:);
                            
                            analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition) = temp.hist_together.fit_success;
                            analysis.hist_together.Poissonian.flag{m_power, m_flux, m_gate, m_detuning, m_repetition} = temp.hist_together.fit_flag;              
                        end
                        %% Plot Poissonian
                        if run_params.analysis.current_run_bistability_existence && run_params.Poisson_fig_plot_param 
                            if run_params.plot_visible == 1 
                                Poissonian_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
                            elseif run_params.plot_visible == 0 
                                Poissonian_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
                            end

                            bar(temp.switch_time_bin_centers_1*1e6, log(temp.hist_count_1), 'r', 'FaceAlpha', 0.25, 'DisplayName', 'State 1 hist')
                            hold on
                            bar(temp.switch_time_bin_centers_2*1e6, log(temp.hist_count_2), 'b', 'FaceAlpha', 0.25, 'DisplayName', 'State 2 hist')
                            plot(temp.switch_time_bin_centers_1*1e6, temp.poisson_theory_1, 'r', 'linewidth', 2, 'DisplayName', 'State 1 fit')
                            plot(temp.switch_time_bin_centers_2*1e6, temp.poisson_theory_2, 'b', 'linewidth', 2, 'DisplayName', 'State 2 fit')
                            xlabel('Switching time ($\mu$s)', 'interpreter', 'latex')
                            ylabel('log(Count)', 'interpreter', 'latex')
                            title(['Poisson fit for P$_{\mathrm{in}}$ = ' num2str(run_params.input_power_value) 'dBm' 13 10 ...
                                '$n_g = $' num2str(run_params.ng_1_value) ', $\Phi_{\mathrm{ext}}$ = ' num2str(run_params.flux_1_value) '$\Phi_0$' 13 10 ...
                                '$\Delta$ = ' num2str(detuning_point) 'MHz' ], 'interpreter', 'latex')
                            legend show
                            annotation('textbox', [0.55, 0.45, 0.5, 0.3], 'String', ['Lifetime state 1 = ' num2str(round(temp.poisson_lifetime_1_us, 2)) ...
                                '$\pm$' num2str(round(temp.error_poisson_lifetime_1_us, 2)) '$ \mu$s'], 'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'r')
                            annotation('textbox', [0.55, 0.35, 0.5, 0.3], 'String', ['Lifetime state 2 = ' num2str(round(temp.poisson_lifetime_2_us, 2)) ...
                                '$\pm$' num2str(round(temp.error_poisson_lifetime_2_us, 2)) '$ \mu$s'], 'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'b')
                            annotation('textbox', [0.35, 0.2, 0.5, 0.3], 'String', ['Total counts = ' num2str(sum(temp.hist_count_1))], ...
                                'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'r')
                            annotation('textbox', [0.35, 0.25, 0.5, 0.3], 'String', ['Total counts = ' num2str(sum(temp.hist_count_2))], ...
                                'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'b')

                            if run_params.save_data_and_png_param == 1
                                    save_file_name = [run_params.rts_fig_directory  num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning)...
                                        '_' num2str(m_repetition) '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) ...
                                        'm_detuning_' num2str(detuning_point) 'MHz_poisson_fit.png'];
                                    saveas(Poissonian_figure, save_file_name)
                                    save_file_name = [run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning)...
                                        '_' num2str(m_repetition) '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_detuning_' num2str(detuning_point) 'MHz_poisson_fit.fig'];
                                    saveas(Poissonian_figure, save_file_name)
                            end
                            clear Poissonian_figure ...
                                  save_file_name
                        end
                        %% Plot Poissonian of together if histogrammed together and separately
                        if squeeze(analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, m_repetition)) == 1 && ...
                                strcmp(run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together') && m_repetition == run_params.number_repetitions
                            if analysis.hist_together.Poissonian.fit_success(m_power, m_flux, m_gate, m_detuning, run_params.number_repetitions) 
                                if run_params.plot_visible == 1 
                                    Poissonian_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
                                elseif run_params.plot_visible == 0 
                                    Poissonian_figure = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
                                end

                                bar(temp.hist_together.switch_time_bin_centers_1*1e6, log(temp.hist_together.hist_count_1), 'r', 'FaceAlpha', 0.25, 'DisplayName', 'State 1 hist')
                                hold on
                                bar(temp.hist_together.switch_time_bin_centers_2*1e6, log(temp.hist_together.hist_count_2), 'b', 'FaceAlpha', 0.25, 'DisplayName', 'State 2 hist')
                                plot(temp.hist_together.switch_time_bin_centers_1*1e6, temp.hist_together.poisson_theory_1, 'r', 'linewidth', 2, 'DisplayName', 'State 1 fit')
                                plot(temp.hist_together.switch_time_bin_centers_2*1e6, temp.hist_together.poisson_theory_2, 'b', 'linewidth', 2, 'DisplayName', 'State 2 fit')
                                xlabel('Switching time ($\mu$s)', 'interpreter', 'latex')
                                ylabel('log(Count)', 'interpreter', 'latex')
                                title(['Poisson fit histogrammed over repetitions for P$_{\mathrm{in}}$ = ' num2str(run_params.input_power_value) 'dBm' 13 10 ...
                                    '$n_g = $' num2str(run_params.ng_1_value) ', $\Phi_{\mathrm{ext}}$ = ' num2str(run_params.flux_1_value) '$\Phi_0$' 13 10 ...
                                    '$\Delta$ = ' num2str(detuning_point) 'MHz' ], 'interpreter', 'latex')
                                legend show
                                annotation('textbox', [0.55, 0.45, 0.5, 0.3], 'String', ['Lifetime state 1 = ' num2str(round(temp.hist_together.poisson_lifetime_1_us, 2)) ...
                                    '$\pm$' num2str(round(temp.hist_together.error_poisson_lifetime_1_us, 2)) '$ \mu$s'], 'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'r')
                                annotation('textbox', [0.55, 0.35, 0.5, 0.3], 'String', ['Lifetime state 2 = ' num2str(round(temp.hist_together.poisson_lifetime_2_us, 2)) ...
                                    '$\pm$' num2str(round(temp.hist_together.error_poisson_lifetime_2_us, 2)) '$ \mu$s'], 'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'b')
                                annotation('textbox', [0.35, 0.2, 0.5, 0.3], 'String', ['Total counts = ' num2str(sum(temp.hist_together.hist_count_1))], ...
                                    'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'r')
                                annotation('textbox', [0.35, 0.25, 0.5, 0.3], 'String', ['Total counts = ' num2str(sum(temp.hist_together.hist_count_2))], ...
                                    'interpreter', 'latex', 'LineStyle', 'none', 'FontSize', 30, 'Color', 'b')

                                if run_params.save_data_and_png_param == 1
                                        save_file_name = [run_params.rts_fig_directory  num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning)...
                                            '_' num2str(m_repetition) '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) ...
                                            'm_detuning_' num2str(detuning_point) 'MHz_poisson_hist_together_fit.png'];
                                        saveas(Poissonian_figure, save_file_name)
                                        save_file_name = [run_params.rts_fig_directory '/fig_files/' num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) '_' num2str(m_detuning)...
                                            '_' num2str(m_repetition) '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_detuning_' ...
                                            num2str(detuning_point) 'MHz_poisson_hist_together_.fig'];
                                        saveas(Poissonian_figure, save_file_name)
                                end
                                clear Poissonian_figure ...
                                      save_file_name
                            end
                        end
                    end
                    analysis.poissonian_lifetime_repetitions_mode{m_power, m_flux, m_gate, m_detuning} = run_params.poissonian_lifetime_repetitions_mod;
                end
                %% finish plot and fit
                clear bias_point_struct ...
                      temp
                close all
                detuning_point = detuning_point + run_params.detuning_point_step;
                m_detuning = m_detuning + run_params.detuning_point_step/0.5; % since the detuning is originally intended to be a step size of 0.5MHz
            end
            data.done_parameter(m_power, m_flux, m_gate) = 1;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
            %% capture final res freq
            connect_instruments
            disp('capturing VNA data at single photon power')
            switch_vna_measurement
            pause(2)
            vna_set_power(vna, -65, 1)
            vna_set_electrical_delay(vna, input_params.vna.electrical_delay, 1, 2);
            vna_turn_output_on(vna)
            vna_set_IF_BW(vna, input_params.vna.rough_IF_BW, 1)
            vna_set_sweep_points(vna, input_params.vna.rough_number_points, 1)
            vna_set_center_span(vna, input_params.vna.rough_center, input_params.vna.rough_span, 1)
            vna_send_average_trigger(vna);
            [data.vna.single_photon.final.rough.freq(m_power, m_flux, m_gate, :), ...
                    data.vna.single_photon.final.rough.amp(m_power, m_flux, m_gate,:)] = ...
                    vna_get_data(vna, 1, 1);
            [~, data.vna.single_photon.final.rough.phase(m_power, m_flux, m_gate,:)] = ...
                    vna_get_data(vna, 1, 2);
            [~,manual_index] = min(squeeze(data.vna.single_photon.final.rough.amp(m_power, m_flux, m_gate,:)) ...
                    - gain_prof.amp');
            rough_resonance = squeeze(data.vna.single_photon.final.rough.freq(m_power, m_flux, m_gate, manual_index));
            data.vna.single_photon.final.rough_resonance (m_power, m_flux, m_gate)= squeeze(data.vna.single_photon.final.rough.freq(m_power, m_flux, m_gate, manual_index));
            data.vna.single_photon.final.res_freq_shift_during_run (m_power, m_flux, m_gate)= data.vna.single_photon.final.rough_resonance (m_power, m_flux, m_gate) - ...
                analysis.vna.single_photon.fits_flucs_and_angle.res_freq(m_power, m_flux, m_gate);
            vna_set_center_span(vna,rough_resonance,input_params.vna.zoom_scan_span,1);
            disp(['start freq = ' num2str(res_freq/1e9) 'GHz, final freq = ' num2str(rough_resonance/1e9) 'GHz. ' 13 10 ...
                'freq shift during run = ' num2str((res_freq - rough_resonance)/1e6) 'MHz'])
            clear manual_index ...
                  rough_resonance ...
                  res_freq 
            vna_set_IF_BW(vna, input_params.vna.IF_BW, 1)
            vna_set_average(vna, input_params.vna.average_number, 1, 1);
            vna_set_sweep_points(vna, input_params.vna.number_points, 1);
            vna_send_average_trigger(vna);
            [data.vna.single_photon.final.fine.freq(m_power, m_flux, m_gate, :), ...
                    data.vna.single_photon.final.fine.amp(m_power, m_flux, m_gate,:)] = ...
                    vna_get_data(vna, 1, 1);
            [~, data.vna.single_photon.final.fine.phase(m_power, m_flux, m_gate,:)] = ...
                    vna_get_data(vna, 1, 2);
            pause(3);
            vna_turn_output_off(vna)
            clear_instruments
        %% Plot lifetime curves
        if run_params.analysis_during_acquisition
            if run_params.plot_visible == 1 
                Lifetime_detuning_plots = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
            elseif run_params.plot_visible == 0 
                Lifetime_detuning_plots = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
            end
            if strcmp(run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together')
                user = input('both separate and together histogramming done. separate histograms plot separately(0) or averaged(1) or histogrammed together (2)?');
            end
            if strcmp(run_params.poissonian_lifetime_repetitions_mode, 'separate') ||(strcmp(run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together') ...
                    && user == 0)% 'separate' or 'averaged', 'histogrammed_together'
                hold on
                for m_repetition = 1 : run_params.number_repetitions
                    temp.x_array = squeeze(data.detunings(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, m_repetition));
                    temp.y_array = squeeze(analysis.Poissonian.lifetime_1(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, m_repetition));
                    temp.y_error = squeeze(analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, m_repetition));
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(run_params.detunings_expected_number, 1)/1e6;
                    temp.x_array(temp.y_array == 0) = NaN;
                    temp.y_error(temp.y_array == 0) = NaN;
                    temp.x_error(temp.y_array == 0) = NaN;
                    temp.y_array(temp.y_array == 0) = NaN;

                    errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                    'rx-', 'Linewidth', 3, 'DisplayName', ['State 1, rep = ' num2str(m_repetition)]) 
                end

                for m_repetition = 1 : run_params.number_repetitions
                    temp.x_array = squeeze(data.detunings(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, m_repetition));
                    temp.y_array = squeeze(analysis.Poissonian.lifetime_2(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, m_repetition));
                    temp.y_error = squeeze(analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, m_repetition));
                    temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(run_params.detunings_expected_number, 1)/1e6;
                    temp.x_array(temp.y_array == 0) = NaN;
                    temp.y_error(temp.y_array == 0) = NaN;
                    temp.x_error(temp.y_array == 0) = NaN;
                    temp.y_array(temp.y_array == 0) = NaN;

                    errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                    'bx-', 'Linewidth', 3, 'DisplayName', ['State 2, rep = ' num2str(m_repetition)]) 
                end
            elseif strcmp(run_params.poissonian_lifetime_repetitions_mode, 'averaged') ||(strcmp(run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together') ...
                    && user == 1)
                temp.x_array = mean(squeeze(data.detunings(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, :)), 2);
                temp.y_array = mean(squeeze(analysis.Poissonian.lifetime_1(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, :)), 2);
                temp.y_error = mean(squeeze(analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, :)), 2);
                temp.x_error = squeeze(analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(run_params.detunings_expected_number, 1))/1e6;
                temp.x_array(temp.y_array == 0) = NaN;
                temp.y_error(temp.y_array == 0) = NaN;
                temp.x_error(temp.y_array == 0) = NaN;
                temp.y_array(temp.y_array == 0) = NaN;

                errorbar(temp.x_array, temp.y_array,temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                    'rx-', 'Linewidth', 3, 'DisplayName', 'State 1 lifetimes')

                hold on

                temp.x_array = mean(squeeze(data.detunings(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, :)), 2);
                temp.y_array = mean(squeeze(analysis.Poissonian.lifetime_2(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, :)), 2);
                temp.y_error = mean(squeeze(analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, :)), 2);
                temp.x_error = squeeze(analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(run_params.detunings_expected_number, 1))/1e6;
                temp.x_array(temp.y_array == 0) = NaN;
                temp.y_error(temp.y_array == 0) = NaN;
                temp.x_error(temp.y_array == 0) = NaN;
                temp.y_array(temp.y_array == 0) = NaN;
                errorbar(temp.x_array, temp.y_array,temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                    'rx-', 'Linewidth', 3, 'DisplayName', 'State 2 lifetimes')

            elseif strcmp(run_params.poissonian_lifetime_repetitions_mode, 'histogrammed_together') 
                temp.x_array = squeeze(data.detunings(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.y_array = squeeze(analysis.Poissonian.lifetime_1(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.y_error = squeeze(analysis.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(run_params.detunings_expected_number, 1)/1e6;

                errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                'rx-', 'Linewidth', 3, 'DisplayName', ['State 1, rep = ' num2str(m_repetition)]) 
                hold on
                temp.x_array = squeeze(data.detunings(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.y_array = squeeze(analysis.Poissonian.lifetime_2(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.y_error = squeeze(analysis.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(run_params.detunings_expected_number, 1)/1e6;

                errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                'bx-', 'Linewidth', 3, 'DisplayName', ['State 2, rep = ' num2str(m_repetition)])     
                
            elseif (strcmp(run_params.poissonian_lifetime_repetitions_mode, 'separate_and_together') && user == 2)    
                temp.x_array = squeeze(data.detunings(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.y_array = squeeze(analysis.hist_together.Poissonian.lifetime_1(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.y_error = squeeze(analysis.hist_together.Poissonian.error_poisson_lifetime_1_us(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(run_params.detunings_expected_number, 1)/1e6;

                errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                'rx-', 'Linewidth', 3, 'DisplayName', ['State 1, rep = ' num2str(m_repetition)]) 
                hold on
                temp.x_array = squeeze(data.detunings(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.y_array = squeeze(analysis.hist_together.Poissonian.lifetime_2(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.y_error = squeeze(analysis.hist_together.Poissonian.error_poisson_lifetime_2_us(m_power, m_flux, m_gate, m_detuning_start:m_detuning_start + run_params.detunings_expected_number - 1, end));
                temp.x_error = analysis.vna.single_photon.fits_flucs_and_angle.sigma(m_power, m_flux, m_gate)*ones(run_params.detunings_expected_number, 1)/1e6;

                errorbar(temp.x_array, temp.y_array, temp.y_error, temp.y_error, temp.x_error, temp.x_error, ...
                'bx-', 'Linewidth', 3, 'DisplayName', ['State 2, rep = ' num2str(m_repetition)])     
            end    
            xlabel('$\Delta$ (MHz)', 'interpreter', 'latex')
            ylabel('Time ($\mu$s)', 'interpreter', 'latex')
            title(['Lifetimes for fit for P$_{\mathrm{in}}$ = ' num2str(run_params.input_power_value) 'dBm' 13 10 ...
                '$n_g = $' num2str(run_params.ng_1_value) ', $\Phi_{\mathrm{ext}}$ = ' num2str(run_params.flux_1_value) '$\Phi_0$'], 'interpreter', 'latex')
            legend show

            if run_params.save_data_and_png_param == 1
                    save_file_name = [run_params.fig_directory num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) '_' num2str(run_params.input_power_value) 'dBm_' ...
                        'ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_lifetimes.png'];
                    saveas(Lifetime_detuning_plots, save_file_name)
                    save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_power) '_' num2str(m_flux) '_' num2str(m_gate) '_' num2str(run_params.input_power_value) 'dBm_' ...
                        'ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_lifetimes.fig'];
                    saveas(Lifetime_detuning_plots, save_file_name)
            end
            clear Lifetime_detuning_plots ...
                  save_file_name ...
                  temp
            close all
        end
        %% make sure to leave on VNA line at the end
        connect_instruments
        switch_vna_measurement
        vna_set_power(vna, -65, 1)
%         vna_turn_output_on(vna)
%         vna_set_center_span(vna, 5.76e9, 250e6, 1)
%         vna_set_trigger_source(vna, 'int')
        clear_instruments
        clear m_power ...
              m_flux ...
              m_gate ...
              m_detuning ...
              m_bias_point ...
              detuning_point ...
              ans ...
              m_detuning_start ...
              m_record ...
              m_save_data_counter ...
              m_save_data_index ...
              systemId ...
              size_required
        %% save run data
        if run_params.save_data_and_png_param == 1
            disp('saving comprehensive run data')
            save([run_params.data_directory '\' run_params.file_name], '-regexp', '^(?!(run_params|raw_data_matrix|bias_point|gain_prof)$).')   
            disp('comprehensive run data saved')
        end
        end
    end
end
clear run_params
%% Function extract Poissonian lifetimes
function [lifetime_1_us, lifetime_2_us, std_exp_fit_state_1, std_exp_fit_state_2, theory_values_state_1, theory_values_state_2, time_bin_centers_state_1, lifetime_state_1_hist_data, ...
    time_bin_centers_state_2,  lifetime_state_2_hist_data, fit_success, flag] =  extract_poissonian_lifetimes(clean_time_data, clean_amp_data, gaussian_1_mean, ...
                                        gaussian_2_mean, min_switching_number, bin_number, hist_count_state_1, ...
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
        lifetime_state_2_hist_data = lifetime_state_2_hist_data(:)+ hist_count_state_2(:);
    else
        [lifetime_state_1_hist_data, time_bin_centers_state_1] = hist(lifetime_state_1_array, bin_number);
        [lifetime_state_2_hist_data, time_bin_centers_state_2] = hist(lifetime_state_2_array, bin_number);
    end
    if length(switching_points) < min_switching_number
        lifetime_1_us = 0;
        lifetime_2_us = 0;
        std_exp_fit_state_1 = 0;
        std_exp_fit_state_2 = 0;
        theory_values_state_1 = NaN;
        theory_values_state_2 = NaN;
        fit_success = 0;
        flag = ['fewer than ' num2str(min_switching_number) ' switches in run'];
        return
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