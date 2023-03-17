%% input params start
%%%% ensure that a 'bias_point_struct' is initialized in the workspace which
%%%% contains :
%%%% flux_zero_voltage, flux_period, gate_offset, gate_period,
%%%% flux_center_freq_mean, gate_values_gate and res_freqs_gate
%%%% and a 'gain_profile_struct' that contains :
%%%% freq, amp, phase
run_params.concatenate_runs = 1; % 0/1 - decides whether this run is going to concatenate data to an existing file
run_params.initialize_or_load  = 1; % 0 - initialize, 1 - load old data. run will pause after loading old data. if it doesn't, run not loaded.
run_params.redo_previously_saved_run = 0; % if this is the same as the previous run, redone for some reason, this will make sure it is overwritten.
% run_params.analysis_during_acquisition = 1; % to analyse during acquisition, or analyse separately.
if run_params.concatenate_runs
    run_params.data_directory = [cd '\data_hysteresis_230314'];
    run_params.file_name = 'hysteresis_comprehensive_data.mat';
end
run_params.save_data_and_png_param = 1; % 0/1 - decides whether to save data and figs or not. 
run_params.save_fig_file_param = 1; % fig file for actual time trace of phase. usually very large for ms data at high sampling
run_params.plot_each_individual_data_slice = 1; % decides whether each(averaged)ramp scan should be plotted or not.
run_params.plot_visible = 0;
run_params.set_with_pre_recorded = 1; %%% verify set res freq with one saved in a pre recorded data set.
input_params.ng_1_value_list = 0: 0.1:0.7;
input_params.flux_1_value_list = 0: 0.04 : .24;
run_params.m_flux = 1;
run_params.m_gate = 7;
run_params.dim_1_placeholder_number = 8;  % if this number is odd, does an increasing power ramp first, then a decreasing. if even, vice versa
run_params.number_ramps_to_average = 5000;

run_params.detuning_point_start = -20; % in MHz % do not exceed +/- 50MHz
run_params.detuning_point_end = 1; % in MHz. 
run_params.detuning_point_step = 0.5; % in MHz. % typically set to 0.5MHz 
m_detuning_start = (run_params.detuning_point_start + 50)/0.5 + 1;
%%% deliberately make expected detuning number large so dont have to worry
%%% about variation in array size. each array point corresponds to -50MHz to
%%% +50, steps of 0.5
input_params.detuning_array_number = 2 * 50 / 0.5 + 1;
run_params.detunings_expected_number = abs((run_params.detuning_point_start - run_params.detuning_point_end)/ run_params.detuning_point_step) + 1;  

%% load gain profile and bias point
if ~exist('gain_prof', 'var')
    disp('enter directory where gain_prof_struct.mat is saved')
    load_directory = 'C:\Users\rimberg-lab\Desktop';
%                 load_directory = 'C:\Users\Sisira\Desktop\feb_16th_2022';
%                load_directory = uigetdir('enter directory where gain_prof_struct.mat is saved');
   load([load_directory '\gain_prof_struct.mat'], 'gain_prof')
   clear load_directory
end

if ~exist('bias_point', 'var') 
   disp('enter directory where bias_point_struct.mat is saved')
   load_directory = 'C:\Users\rimberg-lab\Desktop';
%                 load_directory = 'C:\Users\Sisira\Desktop\feb_16th_2022';
%                load_directory = uigetdir;
   load([load_directory '\bias_point_struct.mat'], 'bias_point')
   clear load_directory
end
% this loads the file with the pre recorded res freqs to compare current value to
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
%% Input params - Attenuation values
input_params.fridge_attenuation = 85.8;
input_params.additional_attenuation = 31.97; % dB. big fridge setup as of 2/11/2023. see notes_feb_11th_2023.txt in folder below
%%%%\\dartfs-hpc\rc\lab\R\RimbergA\cCPT_NR_project\Bhar_measurements\2022_December_Jules_sample\AWG_input_attenuation_calibration
%% Input params -  Analysis params - if analysis being done 
input_params.if_freq = 21e6; % freq to which output signal is mixed down
input_params.number_readout_IF_waveforms_averaged_into_single_point = 7; % the number of power points in the ramp to be averaged into a single point (only for data storage, plotting is done with all points).
input_params.analysis.min_phase_difference = 10; % degs - difference less than this is not real
%% Input params -  AWG and pulse params params
run_params.input_power_start = -140; % dBm at sample
run_params.input_power_stop = -115; % dBm at sample
if mod(run_params.dim_1_placeholder_number, 2) == 0 && run_params.input_power_start< run_params.input_power_stop
    temp = run_params.input_power_start;
    run_params.input_power_start = run_params.input_power_stop;
    run_params.input_power_stop = temp;
end
clear temp
    
run_params.stab_time_at_start_power = 2e-6; % in s. stays constant at the start power for this long at the run start, before acquisition and so on.
run_params.one_way_ramp_time = 8e-6; % in s
run_params.down_time = 10e-6; % in s, down time between repeating ramped pulses
% run_params.trigger_lag = 240e-9;
run_params.trigger_lag = 230e-9;%0;
% this needs to be appropriately set so the switch in direction of
% acquisition falls right in the middle of the acquisition window

input_params.awg.clock = 840e6; % the code is designed for this to be at 840MS/s
input_params.awg.input_IF_waveform_freq = 84e6; % the IF to IQ4509 is at 84MHz, defined in the AWG waveforms
run_params.awg.output_power_start = run_params.input_power_start + input_params.fridge_attenuation + input_params.additional_attenuation;
run_params.awg.output_power_stop = run_params.input_power_stop + input_params.fridge_attenuation + input_params.additional_attenuation; 
run_params.awg.waveform_name = [num2str(round(run_params.input_power_start, 1)) '_to_' num2str(round(run_params.input_power_stop, 1)) 'dBm_' ...
    num2str(round(run_params.stab_time_at_start_power*1e6)) '_stab_' num2str(round(run_params.one_way_ramp_time *1e6, 1)) '_ramp_hyst.wfm'];
%% Input params -  VNA parameter settings
input_params.vna.average_number = 50;
input_params.vna.IF_BW = 1e3;
input_params.vna.number_points = 201;
run_params.vna.power = (run_params.input_power_start + run_params.input_power_stop)/2 + input_params.fridge_attenuation;
input_params.vna.rough_center = 5.76e9;
input_params.vna.rough_span = 250e6;
input_params.vna.rough_IF_BW = 10e3;
input_params.vna.zoom_scan_span = 15e6;
input_params.vna.rough_number_points = 1601;
input_params.vna.electrical_delay = 62.6e-9; 
input_params.vna.rough_smoothing_aperture_amp = 1; % percent
input_params.vna.rough_smoothing_aperture_phase = 1.5; % percent
input_params.vna.zoom_smoothing_aperture_amp = 1; % percent
input_params.vna.zoom_smoothing_aperture_phase = 1.5; % percent

input_params.q_circle_fit.gamma_int_guess = .2e6;
input_params.q_circle_fit.gamma_ext_guess = 1.2e6;
input_params.q_circle_fit.sigma_guess = .5e6;
%% Input params -  Digitizer params
run_params.digitizer.data_collection_time = 2*run_params.one_way_ramp_time; % in seconds. the time to record ramped response
input_params.digitizer.sample_rate = 168e6;
input_params.digitizer.trigger_level = 225; %225 is ~+0.75V for 2Vpp trigger such as marker from AWG
% end
%% input params end   
%% data acquisition loop

%%%% uncomment this for a long run sweeping bias points automatically
% for m_dim_1 = 1 : run_params.dim_1_placeholder_number
    % for m_flux = 1: length(input_params.flux_1_value_list)
    %     for m_gate = 1: length(input_params.ng_1_value_list)
%%%% uncomment this for a single bias  point at a time.
for m_dim_1 = run_params.dim_1_placeholder_number : run_params.dim_1_placeholder_number
    for m_flux = run_params.m_flux : run_params.m_flux
        for m_gate = run_params.m_gate : run_params.m_gate
            m_bias_point = (m_flux - 1)*length(input_params.ng_1_value_list) + m_gate;
            run_params.ng_1_value = input_params.ng_1_value_list(m_gate);
            run_params.flux_1_value = input_params.flux_1_value_list(m_flux);
            
            %%% generate some file names
            date = datetime('now','format', 'yyyy-MM-dd HH:mm:ss Z');
            date = char(date);
            run_params.awg_switching_directory_name = 'sw';
            run_params.awg_directory = ['/' run_params.awg_switching_directory_name '/' date(1:7)];
            clear date;
            if run_params.concatenate_runs
                run_params.fig_directory = [cd '\plots_hysteresis_flux_' num2str(run_params.flux_1_value*1000) 'm\'];
            end

            if run_params.concatenate_runs && run_params.initialize_or_load && ~exist('analysis', 'var')
                load([run_params.data_directory '\' run_params.file_name], '-regexp', '^(?!(run_params|bias_point|gain_prof)$).')  
                disp(['loaded ' run_params.file_name '. Continue?'])
                pause
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
                run_params.data_directory = [cd run_params.root_directory '\data\'];
                clear sign_of_ng ...
                      sign_of_flux
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%
            if ~exist('data','var')
                data.dummy = [];
            end
            if ~isfield(data, 'done_parameter') 
                data.done_parameter = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                rmfield(data, 'dummy');
            end        

            if ~isfield(input_params, 'run_number')
                input_params.run_number = 0;
            elseif run_params.redo_previously_saved_run 
                disp(['suggested run_number - 1 = ' num2str((m_power - 1)/2 *length(input_params.flux_1_value_list)*length(input_params.ng_1_value_list) ...
                    + (m_flux - 1) * length(input_params.ng_1_value_list) + m_gate - 1)])
                input_params.run_number = input('what is the desired run number - 1?');
    %                 input_params.run_number = input_params.run_number - 1;
            end 
            input_params.run_number = input_params.run_number + 1;        
            %% create folders
            if run_params.save_data_and_png_param == 1
                mkdir(run_params.data_directory)
                mkdir(run_params.fig_directory)
                mkdir([run_params.fig_directory '\fig_files'])
            end
            %% prepare run start
            tic;
            %%%%%%%%%%
            disp(['bias point number = ' num2str(m_bias_point) 13 10 ...
                'flux point number = ' num2str(m_flux) ' of ' num2str(length(input_params.flux_1_value_list)) 13 10 ...
                'gate point number = ' num2str(m_gate) ' of ' num2str(length(input_params.ng_1_value_list)) 13 10 ...
                'bias point is ng = ' num2str(run_params.ng_1_value) ', flux = ' num2str(run_params.flux_1_value) 13 10 ...
                'correct bias point number and bias point calibration?'])
    %         pause
            if size(data.done_parameter, 1)> m_dim_1 && (~run_params.redo_previously_saved_run && data.done_parameter(m_dim_1, m_flux, m_gate)) 
                disp('overwriting previously acquired data point. If deliberate, reset "run_params.redo_previously_saved_run" param and rerun')
                return
            end
            %% initialize arrays 
            if ~exist('data', 'var') && run_params.concatenate_runs
                %% arrays for VNA data and analysis single photon
                data.vna.single_photon.rough.freq = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.rough.amp = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.rough.phase = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.rough.real = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.rough.imag = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);

                data.vna.single_photon.fine.freq = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.fine.amp = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.fine.phase = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.fine.real = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.fine.imag = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                %%% for final arrays
                data.vna.single_photon.final.rough.freq = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.final.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.final.rough.amp = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.final.rough.phase = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.final.rough_resonance = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);
                data.vna.single_photon.final.res_freq_shift_during_run = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.rough_number_points);

                data.vna.single_photon.final.fine.freq = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.final.fine.amp = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                data.vna.single_photon.final.fine.phase = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                %%%%%%%%%%%%

                analysis.vna.single_photon.fits_no_flucs.real = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_no_flucs.imag = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_no_flucs.amp = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_no_flucs.phase = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.single_photon.fits_flucs_no_angle.real = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_no_angle.imag = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_no_angle.amp = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_no_angle.phase = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.single_photon.fits_flucs_and_angle.real = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_and_angle.imag = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_and_angle.amp = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.fits_flucs_and_angle.phase = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.single_photon.interp_gain_amp = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.interp_gain_phase = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.subtracted_amp = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);
                analysis.vna.single_photon.subtracted_phase  = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.vna.number_points);

                analysis.vna.single_photon.fits_no_flucs.gamma_ext = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_no_flucs.gamma_int = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_no_flucs.res_freq = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_no_flucs.goodness_fit = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));

                analysis.vna.single_photon.fits_flucs_no_angle.gamma_ext = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_no_angle.gamma_int = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_no_angle.res_freq = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_no_angle.sigma = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_no_angle.goodness_fit = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));

                analysis.vna.single_photon.fits_flucs_and_angle.gamma_ext = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_and_angle.gamma_int = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_and_angle.res_freq = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_and_angle.sigma = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list));
                analysis.vna.single_photon.fits_flucs_and_angle.angle = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list)); 
                analysis.vna.single_photon.fits_flucs_and_angle.goodness_fit = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list)); 
                %% other data arrays
                data.detunings = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                        length(input_params.ng_1_value_list), input_params.detuning_array_number);
                data.recorded_res_freq_GHz = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                        length(input_params.ng_1_value_list), input_params.detuning_array_number);
                data.peripheral.awg_output_power_start = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                        length(input_params.ng_1_value_list), input_params.detuning_array_number);
                data.peripheral.awg_output_power_stop = zeros(run_params.dim_1_placeholder_number, length(input_params.flux_1_value_list), ...
                    length(input_params.ng_1_value_list), input_params.detuning_array_number);
            end
            %% extend some data arrays if ramp time is longer than
            %%% existing arrays
            if exist('analysis', 'var')
                temp.required_data_length_digitizer_all_points = run_params.digitizer.data_collection_time * input_params.digitizer.sample_rate;
                temp.required_data_length_digitizer_averaged_points = run_params.digitizer.data_collection_time * input_params.if_freq / ...
                    input_params.number_readout_IF_waveforms_averaged_into_single_point;
                temp.required_data_length_awg = (run_params.digitizer.data_collection_time + run_params.down_time + run_params.stab_time_at_start_power) * input_params.awg.clock;
                temp.current_data_length_digitizer_all_points = size(analysis.waveform_average_then_phase, 5);
                temp.current_data_length_digitizer_averaged_points = size(analysis.awg_powers_Vp_corresponding_to_averaged_phase_data, 5);
                temp.current_data_length_awg = size(data.wfm.powers_vp, 4);
                if temp.current_data_length_digitizer_all_points < temp.required_data_length_digitizer_all_points
                    analysis.raw_data_averaged(:, :, :, :, temp.required_data_length_digitizer_all_points - temp.current_data_length_digitizer_all_points + 1 : ...
                        temp.required_data_length_digitizer_all_points) = 0;
                    analysis.raw_time_data_averaged(:, :, :, :, temp.required_data_length_digitizer_all_points - temp.current_data_length_digitizer_all_points + 1 : ...
                        temp.required_data_length_digitizer_all_points) = 0;
                    analysis.waveform_average_then_amp(:, :, :, :, temp.required_data_length_digitizer_all_points - temp.current_data_length_digitizer_all_points + 1 : ...
                        temp.required_data_length_digitizer_all_points) = 0;
                    analysis.waveform_average_then_phase(:, :, :, :, temp.required_data_length_digitizer_all_points - temp.current_data_length_digitizer_all_points + 1 : ...
                        temp.required_data_length_digitizer_all_points) = 0;
                    data.sampled_powers_Vp(:, :, :, temp.required_data_length_digitizer_all_points - temp.current_data_length_digitizer_all_points + 1 : ...
                        temp.required_data_length_digitizer_all_points) = 0;
                    analysis.awg_powers_Vp_corresponding_to_averaged_phase_data(:, :, :, :, temp.required_data_length_digitizer_averaged_points - ...
                        temp.current_data_length_digitizer_averaged_points + 1 : temp.required_data_length_digitizer_averaged_points) = 0;
                    analysis.awg_powers_dBm_corresponding_to_averaged_phase_data(:, :, :, :, temp.required_data_length_digitizer_averaged_points - ...
                        temp.current_data_length_digitizer_averaged_points + 1 : temp.required_data_length_digitizer_averaged_points) = 0;

                    analysis.phase_difference_mean_after_demod_averaged_points(:, :, :, :, (temp.required_data_length_digitizer_averaged_points - ...
                        temp.current_data_length_digitizer_averaged_points)/2 + 1 : temp.required_data_length_digitizer_averaged_points/2) = 0;
                    analysis.waveform_average_then_phase_difference(:, :, :, :, (temp.required_data_length_digitizer_all_points - ...
                        temp.current_data_length_digitizer_all_points)/2 + 1 : ...
                        temp.required_data_length_digitizer_all_points/2) = 0;
                end
                if temp.current_data_length_awg < temp.required_data_length_awg
                    data.wfm.powers_vp (:, :, :, temp.required_data_length_awg - temp.current_data_length_awg + 1 : temp.required_data_length_awg)= 0;
                    data.wfm.sin_wave (:, :, :, temp.required_data_length_awg - temp.current_data_length_awg + 1 : temp.required_data_length_awg)= 0;
                    data.wfm.time_axis (:, :, :, temp.required_data_length_awg - temp.current_data_length_awg + 1 : temp.required_data_length_awg)= 0;
                    data.wfm.markers_data (:, :, :, :, temp.required_data_length_awg - temp.current_data_length_awg + 1 : temp.required_data_length_awg)= 0;
                end
                clear temp
            end
            %% detuning and repetition loop initialization
            detuning_point = run_params.detuning_point_start;
            m_detuning = m_detuning_start;
            res_freq = 5.9e9; % initialize well outside cCPT tunability so the VNA function has to find actual resonance.
            while detuning_point < run_params.detuning_point_end + run_params.detuning_point_step
                disp([13 10 13 10 13 10 13 10 ...
                    'running m_detuning = ' num2str(m_detuning - m_detuning_start + 1) ' of ' num2str(run_params.detunings_expected_number * run_params.detuning_point_step/0.5) ...
                    ', each ramp averaged = ' num2str(run_params.number_ramps_to_average)])
                elapsed_time = toc;
                disp(['Elapsed time since start of run : ' num2str(floor(elapsed_time/3600)) 'hrs, ' num2str(floor(mod(elapsed_time, 3600)/60)) 'mins, ' ...
                    num2str(mod(mod(elapsed_time, 3600),60)) 'seconds'])
                %% record some input variables for this run
                if run_params.set_with_pre_recorded
                    data.pre_recorded_res_freq_values_struct(m_dim_1, m_flux, m_gate) = run_params.pre_recorded_struct;
                end            
                data.fridge_attenuation_used(m_dim_1, m_flux, m_gate) = input_params.fridge_attenuation;
                data.awg_additional_attenuation_used(m_dim_1, m_flux, m_gate) = input_params.additional_attenuation;
                data.time_stamp{m_dim_1, m_flux, m_gate} = datestr(now, 'yymmdd_HHMMSS');
                data.elapsed_time_since_loop_start(m_dim_1, m_flux, m_gate, m_detuning) = elapsed_time;
                data.ng_1_value_by_bias_point(m_dim_1, m_bias_point) = run_params.ng_1_value;
                data.flux_1_value_by_bias_point(m_dim_1, m_bias_point) = run_params.flux_1_value;
                data.ng_1_value_by_gate_flux(m_dim_1, m_bias_point) = run_params.ng_1_value;
                data.flux_1_value_by_gate_flux(m_dim_1, m_bias_point) = run_params.flux_1_value;
                data.input_power_value_start(m_dim_1, m_flux, m_gate) = run_params.input_power_start;
                data.input_power_value_stop(m_dim_1, m_flux, m_gate) = run_params.input_power_stop;
                data.AWG_power_value_start(m_dim_1, m_flux, m_gate) = run_params.awg.output_power_start;
                data.AWG_power_value_stop(m_dim_1, m_flux, m_gate) = run_params.awg.output_power_stop;
                data.fridge_top_power_value_start(m_dim_1, m_flux, m_gate) = run_params.awg.output_power_start - input_params.additional_attenuation;
                data.fridge_top_power_value_stop(m_dim_1, m_flux, m_gate) = run_params.awg.output_power_stop - input_params.additional_attenuation;
                data.awg.waveform_name{m_dim_1, m_flux, m_gate} = run_params.awg.waveform_name;
                input_params.detunings(m_dim_1, m_flux, m_gate, m_detuning) = detuning_point;
                input_params.input_power_start(m_dim_1, m_flux, m_gate, m_detuning) = run_params.input_power_start;
                input_params.input_power_stop(m_dim_1, m_flux, m_gate, m_detuning) = run_params.input_power_stop;
                input_params.one_way_ramp_time(m_dim_1, m_flux, m_gate, m_detuning) = run_params.one_way_ramp_time;
                input_params.stab_time_at_start_power(m_dim_1, m_flux, m_gate, m_detuning) = run_params.stab_time_at_start_power;
                data.detunings(m_dim_1, m_flux, m_gate, m_detuning) = detuning_point;
                data.run_number(m_dim_1, m_flux, m_gate, m_detuning) = input_params.run_number;
                input_params.run_order(m_dim_1, m_flux, m_gate, m_detuning) = input_params.run_number;
                data.run_order(m_dim_1, m_flux, m_gate, m_detuning) = input_params.run_number;
                data.detunings(m_dim_1, m_flux, m_gate, m_detuning) = detuning_point;
                data.peripheral.bias_point_offset_and_periods(m_dim_1, m_flux, m_gate) = bias_point;
                data.peripheral.gain_profile(m_dim_1, m_flux, m_gate) = gain_prof;
                data.peripheral.awg_output_power_start(m_dim_1, m_flux, m_gate) = run_params.awg.output_power_start;
                data.peripheral.awg_output_power_stop(m_dim_1, m_flux, m_gate) = run_params.awg.output_power_stop;
                data.peripheral.data_collection_time(m_dim_1, m_flux, m_gate) = run_params.digitizer.data_collection_time;
                data.number_ramps_to_average(m_dim_1, m_flux, m_gate, m_detuning) = run_params.number_ramps_to_average;
                input_params.vna.input_power(m_dim_1, m_flux, m_gate) = run_params.vna.power;
                %% decide whether to collect res freq, generate sequence, set bias and so on
                if detuning_point == run_params.detuning_point_start
                    vna_data_acquisition = 1;
                    res_freq_recorder = 1;
                    bias_set_param = 1;
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
                power_ramp_hysteresis_for_single_cCPT_setting
                %%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% record some other data variables
                data.drive_freq_GHz(m_dim_1, m_flux, m_gate, m_detuning) = detuning_point/1e3 + res_freq/1e9;
                data.recorded_res_freq_GHz(m_dim_1, m_flux, m_gate) = res_freq/1e9;
                data.kerr_MHz(m_dim_1, m_flux, m_gate) = kerr_MHz_expected_for_Jules_sample(run_params.ng_1_value, run_params.flux_1_value);
                %% finish plot and fit
                clear bias_point_struct ...
                      temp
                close all
                detuning_point = detuning_point + run_params.detuning_point_step;
                m_detuning = m_detuning + run_params.detuning_point_step/0.5; % since the detuning is originally intended to be a step size of 0.5MHz
            end
            data.done_parameter(m_dim_1, m_flux, m_gate) = 1;
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
            [data.vna.single_photon.final.rough.freq(m_dim_1, m_flux, m_gate, :), ...
                    data.vna.single_photon.final.rough.amp(m_dim_1, m_flux, m_gate,:)] = ...
                    vna_get_data(vna, 1, 1);
            [~, data.vna.single_photon.final.rough.phase(m_dim_1, m_flux, m_gate,:)] = ...
                    vna_get_data(vna, 1, 2);
            [~,manual_index] = min(squeeze(data.vna.single_photon.final.rough.amp(m_dim_1, m_flux, m_gate,:)) ...
                    - gain_prof.amp');
            rough_resonance = squeeze(data.vna.single_photon.final.rough.freq(m_dim_1, m_flux, m_gate, manual_index));
            data.vna.single_photon.final.rough_resonance (m_dim_1, m_flux, m_gate)= squeeze(data.vna.single_photon.final.rough.freq(m_dim_1, m_flux, m_gate, manual_index));
            data.vna.single_photon.final.res_freq_shift_during_run (m_dim_1, m_flux, m_gate)= data.vna.single_photon.final.rough_resonance (m_dim_1, m_flux, m_gate) - ...
                analysis.vna.single_photon.fits_flucs_and_angle.res_freq(m_dim_1, m_flux, m_gate);
            vna_set_center_span(vna,rough_resonance,input_params.vna.zoom_scan_span,1);
            clear manual_index ...
                  rough_resonance
            vna_set_IF_BW(vna, input_params.vna.IF_BW, 1)
            vna_set_average(vna, input_params.vna.average_number, 1, 1);
            vna_set_sweep_points(vna, input_params.vna.number_points, 1);
            vna_send_average_trigger(vna);
            [data.vna.single_photon.final.fine.freq(m_dim_1, m_flux, m_gate, :), ...
                    data.vna.single_photon.final.fine.amp(m_dim_1, m_flux, m_gate,:)] = ...
                    vna_get_data(vna, 1, 1);
            [~, data.vna.single_photon.final.fine.phase(m_dim_1, m_flux, m_gate,:)] = ...
                    vna_get_data(vna, 1, 2);
            [~,min_index] = min(squeeze(data.vna.single_photon.final.fine.amp(m_dim_1, m_flux, m_gate,:)));
        %     rough_resonance = 5.813e9;
            data.vna.single_photon.final.fine.min_amp_freq (m_dim_1, m_flux, m_gate) = squeeze(data.vna.single_photon.final.fine.freq(m_dim_1, m_flux, m_gate, min_index));
            data.vna.single_photon.final.fine.res_freq_shift_during_run (m_dim_1, m_flux, m_gate)= data.vna.single_photon.final.fine.min_amp_freq (m_dim_1, m_flux, m_gate) - ...
                analysis.vna.single_photon.fits_flucs_and_angle.res_freq(m_dim_1, m_flux, m_gate);
            disp(['start freq = ' num2str(res_freq/1e9) 'GHz, final freq = ' ...
                num2str(squeeze(data.vna.single_photon.final.fine.min_amp_freq (m_dim_1, m_flux, m_gate))/1e9) 'GHz. ' 13 10 ...
                'freq shift during run = ' num2str((res_freq - ...
                squeeze(data.vna.single_photon.final.fine.min_amp_freq (m_dim_1, m_flux, m_gate)))/1e6) 'MHz'])
            clear min_index ...
                  res_freq
            pause(3);
            vna_turn_output_off(vna)
            clear_instruments
            %% plot surf plot of detuning vs power and phase diff
            temp.detuning_vector = squeeze(data.detunings(m_dim_1, m_flux, m_gate, :));
            temp.detuning_vector(temp.detuning_vector == 0) = [];       
            temp.powers_vector = convert_Vp_to_dBm(squeeze(data.sampled_powers_Vp(m_dim_1, m_flux, m_gate,...
                1:run_params.digitizer.data_collection_time * input_params.digitizer.sample_rate/2))) ...
                    - input_params.fridge_attenuation - input_params.additional_attenuation;
            %%%% plot of phase difference vs detuning and powers for phase
            %%%% then average
            if run_params.plot_visible == 1
                surf_plot_phase_then_average_fig = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
            elseif run_params.plot_visible == 0 
                surf_plot_phase_then_average_fig = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
            end
            temp.data_array = squeeze(analysis.temp.phase_difference_mean_after_demod_all_points(m_detuning_start:m_detuning_start - 1+ ...
                length(temp.detuning_vector),:));
            temp.data_array(temp.data_array < input_params.analysis.min_phase_difference) = 0;
            surf(temp.detuning_vector, temp.powers_vector, temp.data_array', 'linestyle', 'none')
            view(0,90)
            xlabel('$\Delta$ (MHz)', 'interpreter', 'latex')
            ylabel('$P_{\mathrm{in}}$ (dBm)', 'interpreter', 'latex')
            h = colorbar;
            caxis([input_params.analysis.min_phase_difference 50])
            ylabel(h, 'Phase diff ($^\circ$)', 'interpreter', 'latex', 'rotation', 90)    
            if run_params.save_data_and_png_param == 1
                save_file_name = [run_params.fig_directory num2str(m_dim_1) '_' num2str(m_flux) '_' num2str(m_gate) ...
                    '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_1way_ramp_time_' ...
                    num2str(round(run_params.one_way_ramp_time*1e6)) 'us_phase_then_average.png'];
                saveas(surf_plot_phase_then_average_fig, save_file_name)
            end
            if run_params.save_fig_file_param == 1
                save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_dim_1) '_' num2str(m_flux) '_' num2str(m_gate) ...
                    '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_1way_ramp_time_' ...
                    num2str(round(run_params.one_way_ramp_time*1e6)) 'us_phase_then_average.fig'];
                saveas(surf_plot_phase_then_average_fig, save_file_name)
            end
            clear surf_plot_phase_then_average_fig ...
                  save_file_name
              
            %%% plot of phase difference vs detuning and powers for phase
            %%%% then average
            if run_params.plot_visible == 1
                surf_plot_average_then_phase_fig = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
            elseif run_params.plot_visible == 0 
                surf_plot_average_then_phase_fig = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
            end
            temp.powers_vector = convert_Vp_to_dBm(squeeze(data.sampled_powers_Vp(m_dim_1, m_flux, m_gate, ...
                1:run_params.digitizer.data_collection_time * input_params.digitizer.sample_rate/2))) ...
                    - input_params.fridge_attenuation - input_params.additional_attenuation;
            temp.data_array_average_then_phase = squeeze(analysis.waveform_average_then_phase_difference(m_dim_1, m_flux, m_gate, m_detuning_start:m_detuning_start - 1 + ...
                length(temp.detuning_vector),1:run_params.digitizer.data_collection_time * input_params.digitizer.sample_rate/2));
            temp.data_array_average_then_phase(temp.data_array_average_then_phase < input_params.analysis.min_phase_difference) = 0;
            surf(temp.detuning_vector, temp.powers_vector, temp.data_array_average_then_phase', 'linestyle', 'none')
            view(0,90)
            xlabel('$\Delta$ (MHz)', 'interpreter', 'latex')
            ylabel('$P_{\mathrm{in}}$ (dBm)', 'interpreter', 'latex')
            h = colorbar;
            caxis([input_params.analysis.min_phase_difference 50])
            ylabel(h, 'Phase diff ($^\circ$)', 'interpreter', 'latex', 'rotation', 90)    
            if run_params.save_data_and_png_param == 1
                save_file_name = [run_params.fig_directory num2str(m_dim_1) '_' num2str(m_flux) '_' num2str(m_gate) ...
                    '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_1way_ramp_time_' ...
                    num2str(round(run_params.one_way_ramp_time*1e6)) 'us_average_then_phase.png'];
                saveas(surf_plot_average_then_phase_fig, save_file_name)
            end
            if run_params.save_fig_file_param == 1
                save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_dim_1) '_' num2str(m_flux) '_' num2str(m_gate) ...
                    '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_1way_ramp_time_' ...
                    num2str(round(run_params.one_way_ramp_time*1e6)) 'us_average_then_phase_difference.fig'];
                saveas(surf_plot_average_then_phase_fig, save_file_name)
            end
            clear surf_plot_average_then_phase_fig ...
                  save_file_name ...
                  h
              
            %%% plot of alternating forward and reverse scans - phase then
            %%% average
            if run_params.plot_visible == 1
                surf_plot_alternating_phase_then_average_fig = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
            elseif run_params.plot_visible == 0 
                surf_plot_alternating_phase_then_average_fig = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
            end
            temp.powers_vector = convert_Vp_to_dBm(squeeze(data.sampled_powers_Vp(m_dim_1, m_flux, m_gate, ...
                1:run_params.digitizer.data_collection_time * input_params.digitizer.sample_rate/2))) ...
                    - input_params.fridge_attenuation - input_params.additional_attenuation;
            temp.data_array = squeeze(analysis.temp.phase_alternating_after_demod_all_points(m_detuning_start:m_detuning_start - 1+ ...
                length(temp.detuning_vector),:));
            surf(temp.detuning_vector, temp.powers_vector, temp.data_array', 'linestyle', 'none')
            view(0,90)
            xlabel('$\Delta$ (MHz)', 'interpreter', 'latex')
            ylabel('$P_{\mathrm{in}}$ (dBm)', 'interpreter', 'latex')
            h = colorbar;
            caxis([-30 30])
            ylabel(h, 'Phase ($^\circ$)', 'interpreter', 'latex', 'rotation', 90)    
            if run_params.save_data_and_png_param == 1
                save_file_name = [run_params.fig_directory num2str(m_dim_1) '_' num2str(m_flux) '_' num2str(m_gate) ...
                    '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_1way_ramp_time_' ...
                    num2str(round(run_params.one_way_ramp_time*1e6)) 'us_alternating_phase_then_average.png'];
                saveas(surf_plot_alternating_phase_then_average_fig, save_file_name)
            end
            if run_params.save_fig_file_param == 1
                save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_dim_1) '_' num2str(m_flux) '_' num2str(m_gate) ...
                    '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_1way_ramp_time_' ...
                    num2str(round(run_params.one_way_ramp_time*1e6)) 'us_alternating_phase_then_average.fig'];
                saveas(surf_plot_alternating_phase_then_average_fig, save_file_name)
            end
            clear surf_plot_alternating_phase_then_average_fig ...
                  save_file_name
            %%% plot of alternating forward and reverse scan phase vs detuning and powers for phase
            %%%% then average
            if run_params.plot_visible == 1
                surf_plot_alternating_average_then_phase_fig = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
            elseif run_params.plot_visible == 0 
                surf_plot_alternating_average_then_phase_fig = figure('units', 'normalized', 'outerposition', [0 0 1 1],'visible','off');
            end
            temp.powers_vector = convert_Vp_to_dBm(squeeze(data.sampled_powers_Vp(m_dim_1, m_flux, m_gate, ...
                1:run_params.digitizer.data_collection_time * input_params.digitizer.sample_rate/2))) ...
                    - input_params.fridge_attenuation - input_params.additional_attenuation;
            temp.data_array_average_then_phase = squeeze(analysis.alternating_average_then_phase(m_dim_1, m_flux, m_gate, m_detuning_start:m_detuning_start - 1 + ...
                length(temp.detuning_vector),1:run_params.digitizer.data_collection_time * input_params.digitizer.sample_rate/2));
            surf(temp.detuning_vector, temp.powers_vector, temp.data_array_average_then_phase', 'linestyle', 'none')
            view(0,90)
            xlabel('$\Delta$ (MHz)', 'interpreter', 'latex')
            ylabel('$P_{\mathrm{in}}$ (dBm)', 'interpreter', 'latex')
            h = colorbar;
            caxis([-30 30])
            ylabel(h, 'Phase ($^\circ$)', 'interpreter', 'latex', 'rotation', 90)    
            if run_params.save_data_and_png_param == 1
                save_file_name = [run_params.fig_directory num2str(m_dim_1) '_' num2str(m_flux) '_' num2str(m_gate) ...
                    '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_1way_ramp_time_' ...
                    num2str(round(run_params.one_way_ramp_time*1e6)) 'us_alternating_average_then_phase.png'];
                saveas(surf_plot_alternating_average_then_phase_fig, save_file_name)
            end
            if run_params.save_fig_file_param == 1
                save_file_name = [run_params.fig_directory '\fig_files\' num2str(m_dim_1) '_' num2str(m_flux) '_' num2str(m_gate) ...
                    '_ng_' num2str(run_params.ng_1_value) '_flux_' num2str(run_params.flux_1_value*1000) 'm_1way_ramp_time_' ...
                    num2str(round(run_params.one_way_ramp_time*1e6)) 'us_alternating_average_then_phase_difference.fig'];
                saveas(surf_plot_alternating_average_then_phase_fig, save_file_name)
            end
            clear surf_plot_alternating_average_then_phase_fig ...
                  save_file_name ...
                  temp ...
                  h
            analysis = rmfield(analysis, 'temp');
            %% make sure to leave on VNA line at the end
            connect_instruments
            switch_vna_measurement
            vna_set_power(vna, -65, 1)
        %         vna_turn_output_on(vna)
        %         vna_set_center_span(vna, 5.76e9, 250e6, 1)
        %         vna_set_trigger_source(vna, 'int')
            clear_instruments
            clear m_dim_1 ...
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
            save_confirm = 0;
            while save_confirm ~= 1 && save_confirm ~= 101
                save_confirm = input('did the resonance freq stay steady during the run? save data? 0/1');
                if save_confirm ~=1
                    save_confirm = input('confirm discard of run (101 to discard, 1 to actually save)');
                end
            end
            if run_params.save_data_and_png_param == 1 && save_confirm == 1
                clear save_confirm
                disp('saving comprehensive run data')
                save([run_params.data_directory '\' run_params.file_name], '-regexp', '^(?!(run_params|raw_data_matrix|bias_point|gain_prof)$).')   
                disp('comprehensive run data saved')
            end
        end
    end
end
clear run_params