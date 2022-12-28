function [time_data, amplitude_data]=tds_get_data(tds_handle,channel,start_point,stop_point)
    if ~exist('start_point','var')
        start_point=1;
    end
    tds_set_channel(tds_handle,channel);
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    address_string = ['GPIB0::' num2str(address) '::INSTR'];
    clear tds_handle
    tds_handle=visa('ni',address_string);
    tds_handle.InputBufferSize = 200000*1024;
    tds_handle.OutputBufferSize = 2000*1024;
    fopen(tds_handle)
%     query(tds_handle,'*IDN?')
%     pause
    record_length=str2num(query(tds_handle,'hor:reco?'))
    pause
    if ~exist('stop_point','var')
        stop_point=record_length;
    end
    fwrite(tds_handle,'wfmo:byt_n 1');
    fwrite(tds_handle,'data:encdg rib');
    
    fwrite(tds_handle,['data:start ' num2str(start_point)]);
    fwrite(tds_handle,['data:stop ' num2str(stop_point)]);
    
    fwrite(tds_handle,'curve?');
    fread(tds_handle,1);       % # character
    length_bytes=str2num(char(fread(tds_handle,1)));
    number_bytes=str2double(char(fread(tds_handle,length_bytes)));
    
    amplitude_data=fread(tds_handle,number_bytes,'int8');
    fread(tds_handle,1);    % LF character
    
    x_incr=str2num(query(tds_handle,'wfmo:xincr?'));
    x_zero=str2num(query(tds_handle,'wfmo:xzero?'));
    y_incr=str2num(query(tds_handle,'wfmo:ymult?'));
    y_off=str2num(query(tds_handle,'wfmo:yoff?'));
    y_zero=str2num(query(tds_handle,'wfmo:yzero?'));

    x_range=record_length*x_incr;
    x_max=x_range+x_zero;
    time_data=linspace(x_zero,x_max,stop_point)';
    
    amplitude_data=((amplitude_data-y_off)*y_incr)+y_zero;
    
    fclose(tds_handle)
    delete(tds_handle)
end
