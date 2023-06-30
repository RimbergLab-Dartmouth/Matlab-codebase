%% run parameters
input_params.flux_bias = 0;
input_params.gate_bias = 0;
monitoring_time_spacing = 10; % in seconds
input_params.min_finder.channel_number = 1;
input_params.min_finder.trace_number = 1;
input_params.min_finder.marker_number = 1;
input_params.initial_min_set_marker = 2;

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
vna_marker_tracking(vna,input_params.min_finder.marker_number,'on',input_params.min_finder.channel_number,input_params.min_finder.trace_number) % turns marker tracking on 
vna_marker_search(vna,input_params.min_finder.marker_number,...
             'min','on',input_params.min_finder.channel_number,input_params.min_finder.trace_number);
i = 1;
loop_running = true;
tic
 while loop_running
    pause(monitoring_time_spacing)
    %%%% set one marker at the initial res freq
    if i == 1
        [data.initial_res_freq, ~, ~]=vna_marker_search(vna,input_params.initial_min_set_marker,...
             'min','on',input_params.min_finder.channel_number,input_params.min_finder.trace_number);
         vna_set_marker_freq(vna,input_params.initial_min_set_marker,data.initial_res_freq,input_params.min_finder.channel_number)
         vna_set_center_span(vna, data.initial_res_freq, input_params.vna.zoom_span, input_params.min_finder.channel_number);
         vna_set_IF_BW(vna, input_params.vna.zoom_IF_BW, input_params.min_finder.channel_number);
         vna_set_average(vna, input_params.vna.zoom_average-number, input_params.min_finder.channel_number);
         vna_set_sweep_points(vna, input_params.vna.zoom_number_points, input_params.min_finder.channel_number);
    end
    data.res_freq_array(i) = vna_get_marker_data(vna,input_params.min_finder.marker_number,...
    input_params.min_finder.channel_number,input_params.min_finder.trace_number);
    data.time(i) = toc;
    %%%%%
    plot(data.time, data.res_freq_array)
    drawnow
    i = i + 1;
 end
