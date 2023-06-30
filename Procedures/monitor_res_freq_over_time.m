%% run parameters
input_params.flux_bias = 0;
input_params.gate_bias = 0;
input_params.monitoring_time_spacing = 10; % in seconds
input_params.min_finder.channel_number = 1;
input_params.min_finder.trace_number = 1;
input_params.min_finder.marker_number = 1;
input_params.initial_min_set_marker = 2;
input_params.data_saving_time_interval = 1500; % in seconds
input_params.save_data_and_png_param = 1;
input_params.save_fig_param = 1;
%% VNA parameter settings
input_params.vna.rough_average_number = 35;
input_params.vna.rough_center = 5.76e9;
input_params.vna.rough_span = 250e6;
input_params.vna.rough_IF_BW = 10e3;
input_params.vna.rough_number_points = 1601;
input_params.vna.zoom_span = 20e6;
input_params.vna.zoom_IF_BW = 1e3;
input_params.vna.zoom_average_number = 50;
input_params.vna.zoom_number_points = 301;
input_params.vna.electrical_delay = 62.6e-9; 

%% set bias point
set_bias_point_using_offset_period_struct(input_params.gate_bias, input_params.flux_bias,bias_point, 0,1,vna);
%% monitoring code
%%% generate folder name
if input_params.save_data_and_png_param == 1 || input_params.save_fig_param == 1
    input_params.file_name_time_stamp = datestr(now, 'yymmdd_HHMMSS');
    run_params.file_name = ['_res_freq_drift' num2str(input_params.gate_bias*100) '_flux_0p' num2str(input_params.flux_bias*100)];
end
%%% make necessary folders
if input_params.save_data_and_png_param 
    mkdir([cd '/d' input_params.file_name_time_stamp input_params.file_name]);
    input_params.fig_directory = [cd '/d' input_params.file_name_time_stamp input_params.file_name '\plots\'];
    input_params.data_directory = [cd '/d' input_params.file_name_time_stamp input_params.file_name '\data\'];
    mkdir([input_params.data_directory]);
end
if input_params.save_fig_param || input_params.save_data_and_png_param
    mkdir([input_params.fig_directory '\fig_files']);
end
vna_marker_tracking(vna,input_params.min_finder.marker_number,'on',input_params.min_finder.channel_number,input_params.min_finder.trace_number) % turns marker tracking on 
vna_marker_search(vna,input_params.min_finder.marker_number,...
             'min','on',input_params.min_finder.channel_number,input_params.min_finder.trace_number);
run_params.i = 1;
run_params.loop_running = true;
run_params.last_save_time = 0;
tic
 while run_params.loop_running
    pause(input_params.monitoring_time_spacing)
    %%%% set one marker at the initial res freq
    if run_params.i == 1
        [data.initial_res_freq, ~, ~]=vna_marker_search(vna,input_params.initial_min_set_marker,...
             'min','on',input_params.min_finder.channel_number,input_params.min_finder.trace_number);
         vna_set_marker_freq(vna,input_params.initial_min_set_marker,data.initial_res_freq,input_params.min_finder.channel_number)
         vna_set_center_span(vna, data.initial_res_freq, input_params.vna.zoom_span, input_params.min_finder.channel_number);
         vna_set_IF_BW(vna, input_params.vna.zoom_IF_BW, input_params.min_finder.channel_number);
         vna_set_average(vna, input_params.vna.zoom_average-number, input_params.min_finder.channel_number);
         vna_set_sweep_points(vna, input_params.vna.zoom_number_points, input_params.min_finder.channel_number);
    end
    data.res_freq_array(run_params.i) = vna_get_marker_data(vna,input_params.min_finder.marker_number,...
    input_params.min_finder.channel_number,input_params.min_finder.trace_number);
    data.time(run_params.i) = toc;
    %%%%%
    plot(data.time, data.res_freq_array)
    drawnow
    if data.time(run_params.i) - run_params.last_save_time > input_params.data_saving_time_interval
        save([input_params.data_directory input_params.file_name '.mat'], '-regexp', '^(?!(run_params)$).')
    end
    run_params.i = run_params.i + 1;
 end