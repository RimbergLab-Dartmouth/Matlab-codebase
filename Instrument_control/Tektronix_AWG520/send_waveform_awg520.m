function[message]=send_waveform_awg520(awg_handle,time,data,marker,wfm_name)  %data is an array of n doubles. marker is a 
if isrow(data)==0 && iscolumn(data)==0                                 % 2xn array of 0s and 1s.
    warning('check data entry');
end
if isempty(marker)
    marker = zeros(2, length(data));
    disp('generating dummy 0 marker')
end

if isrow(data)
    data=data';
end
if size(marker,2)==length(data) && size(marker,1)==2
    marker=marker';
elseif size(marker,1)==length(data) && size(marker,2)==2
else
    warning('check marker entry');
end
marker_bit=uint8(zeros(length(data),1));
data=single(data);
if (abs(diff(time)-mean(diff(time)))>1e-19)
    warning('check time data');
else
    clock=1/mean(diff(time));
end
% set(awg_handle,'Timeout',1000)
for i=1:length(data)
    if marker(i,1)==0 && marker(i,2)==0
        marker_bit(i)=0;
    elseif marker(i,1)==1 && marker (i,2)==0
        marker_bit(i)=1;
    elseif marker(i,1)==0 && marker(i,2)==1
        marker_bit(i)=2;
    elseif marker(i,1)==1 && marker (i,2)==1
        marker_bit(i)=3;
    else
        warning('check marker');
        break
    end
end
clock_string=num2str(clock);
% clock_string=num2str(8.1920000000e+08)
trailer_message=uint8(['CLOCK ' num2str(clock_string) 13 10]);
fclose(awg_handle);
awg_handle.TimeOut=300;
awg_handle.OutputBufferSize=length(data)*5+1000;
fopen(awg_handle);
awg_handle.ByteOrder='littleEndian';
data_message=typecast([],'uint8');
for i=1:length(data)
    data_message=[data_message typecast(data(i),'uint8') marker_bit(i)];
end
length_data=length(data_message);
length_trailer=length(trailer_message);
digits_data=length(num2str(length_data));
header=['MAGIC 1000' 13 10 '#' num2str(digits_data) num2str(length_data)];
header_length=length(header);
total_length=length_data+length_trailer+header_length;
total_digits=length(num2str(total_length));
header_message=uint8([':mmem:data "' wfm_name '.wfm",#' num2str(total_digits) num2str(total_length)...
    header]);
% ([':mmem:data "' wfm_name '.wfm",#' num2str(total_digits) num2str(total_length)...
%     header])
% length(data_message)
% char(header_message)
message=[header_message data_message trailer_message];
fwrite(awg_handle,message);
disp('Waveform sent')

    