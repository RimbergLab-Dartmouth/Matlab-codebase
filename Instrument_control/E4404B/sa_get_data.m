function [freq,amp]=sa_get_data(sa_handle)  %uses all previous settings. restarts averaging and collects data at end
    sweep_points=str2num(query(sa_handle,':sense:sweep:points?'));
    start_freq=str2num(query(sa_handle,':sense:freq:start?'));
    stop_freq=str2num(query(sa_handle,':sense:freq:stop?'));
    fclose(sa_handle)
    if sweep_points<202
        set(sa_handle,'InputBufferSize',8040); 
    elseif 201<sweep_points && sweep_points<402
        set(sa_handle,'InputBufferSize',16040);
    elseif 401<sweep_points && sweep_points<802
        set(sa_handle,'InputBufferSize',32040);
    elseif 801<sweep_points && sweep_points<1602
        set(sa_handle,'InputBufferSize',128080);
    else
        print('Number of points too large');
    end
    fopen(sa_handle)
     average_number=str2num(query(sa_handle,':aver:count?'));
     on_off_number=str2num(query(sa_handle,':aver:stat?'));
     if on_off_number==1
         on_off='on';
     elseif on_off_number==0
         on_off='off';
     end         
     sa_set_avg(sa_handle,average_number,on_off)
     amp_string=query(sa_handle,':TRAC:DATA? TRACE1');
     amp_split_string=strsplit(amp_string,',');
     amp=str2double(amp_split_string);
     freq=linspace(start_freq,stop_freq,sweep_points);
end