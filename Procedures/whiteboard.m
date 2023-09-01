time_stamp = datestr(now, 'mm.dd.yy_HH.MM.SS');
mkdir([cd '/d' time_stamp '_whiteboard']);
dataout.a = [1,2,3,4];
dataout.b = [4,2,3,4];
plot(dataout.b, dataout.a);
clearvars -except time_stamp dataout
save([cd '/d' time_stamp '_whiteboard/white_board_data.mat'])
saveas(gcf,[cd '/d' time_stamp '_whiteboard/white_board.fig'])
plot(dataout.a, dataout.b);
saveas(gcf,[cd '/d' time_stamp '_whiteboard/white_board2.fig'])


% clearvars -except rough_gain_prof input_params data
% save([cd '/d' input_params.file_name_time_stamp '_gain_profile/rough_gain_profile_and_data.mat'])
% 
% [gain_prof.freq,gain_prof.amp,gain_prof.phase]=extract_gain_profile_v2_struct(data.freq, data.amp, data.phase, rough_gain_prof, ...
%     input_params.fine_gain_profile_exclude_span, input_params.plot_display);
% 
% saveas(gcf,[cd '/d' input_params.file_name_time_stamp '_gain_profile/gain_profile.fig'])
% saveas(gcf,[cd '/d' input_params.file_name_time_stamp '_gain_profile/gain_profile.png'])
% 
% clearvars -except gain_prof input_params
% 
% save([cd '/d' input_params.file_name_time_stamp '_gain_profile/gain_prof_struct.mat'])