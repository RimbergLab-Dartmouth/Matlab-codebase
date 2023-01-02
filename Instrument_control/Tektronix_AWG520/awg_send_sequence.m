%%% fill in the waveform names for each line and their repeat count. 
function [message_out, message_ascii] = awg_send_sequence(awg_handle, number_lines, number_channels, waveform_file_array, repeat_count_array, sequence_name, repeat_sequence)
% repeat count of 0 for any line means that line will repeat infinitely
% repeat sequence 1 implies will go back to line 1 at the end of each
% implementation of sequence - sequence repeats indefinitely

%%% Example waveform file %%%%%%  2 channel, 3 lines
% waveform_files = strings(2, 3); % creates empty string array
% waveform_files(1,1) = 'a1';
% waveform_files(1,2) = 'a2';
% waveform_files(1,3) = 'a3';
% waveform_files(2,3) = 'b3';
% waveform_files(2,2) = 'b2';
% waveform_files(2,1) = 'b1';
% repeat_count_array = [1; 2; 3;];
%%%%%%%%%

    if number_channels == 1
        header = ['MAGIC 3001' 13 10];
        if size(waveform_file_array,2) == 1
            waveform_file_array = waveform_file_array';
        elseif size(waveform_file_array,1) == 1
            waveform_file_array = waveform_file_array;
        else
            error('waveform file array is not of suitable size for single channel')
        end
        ch1_file_array = waveform_file_array;
        ch2_file_array = strings(size(waveform_file_array));
    elseif number_channels == 2
        header = ['MAGIC 3002' 13 10];
        if size(waveform_file_array,2) == 2
            waveform_file_array = waveform_file_array';
        elseif size(waveform_file_array,1) == 2
            waveform_file_array = waveform_file_array;
        else
            error('waveform file array is not of suitable size for two channels')
        end
        ch1_file_array = waveform_file_array(1,:);
        ch2_file_array = waveform_file_array(2,:);
    end
    
    if ~isvector(repeat_count_array)
        error('Repeat count array needs to be a vector')
	end
    
    if size(waveform_file_array,2) ~= number_lines
        error('Number of waveform files array does not match number of lines')
    end
    
    if length(repeat_count_array) ~= number_lines
        error('Repeat count array does not match number of lines')
    end

    
    line_message = strings(1, number_lines);
    if number_channels == 1
            concatenated_ch_message = strcat({'"'}, ch1_file_array, {'.wfm"'});
    elseif number_channels == 2
        concatenated_ch_message = strcat({'"'}, ch1_file_array, {'.wfm"'}, {','}, {'"'}, ch2_file_array, {'.wfm"'});
    end
    
    for i = 1 : number_lines
        line_message(i) = strcat(concatenated_ch_message(i), {','}, num2str(repeat_count_array(i)));
        if i == number_lines && repeat_sequence == 1
            line_message(i) = strcat(line_message(i),{','}, num2str(0), {','}, num2str(1)); % sets wait trigger to 0 and goto one to 1 for the last line of sequence
        end
        line_message(i) = join([line_message(i) char(13) newline ], '');
    end
    
%     message_out = convertStringsToChars(join([':mmem:data "',sequence_name,'",', header,'LINES ', num2str(number_lines), char(13), newline, line_message], '')); 
% %     fwrite(awg_handle, message_out)
% 	fprintf(awg_handle, message_out)

    message_body = convertStringsToChars(join([header,'LINES ', num2str(number_lines), char(13), newline, line_message], ''));
    body_length = length(message_body);
    digits = length(num2str(body_length));
    message_ascii = [':mmem:data "',sequence_name,'.seq",#', num2str(digits), num2str(body_length), message_body];
    message_out = uint8([':mmem:data "',sequence_name,'.seq",#', num2str(digits), num2str(body_length), message_body]); 
    fwrite(awg_handle, message_out)
    disp('sequence sent')
end