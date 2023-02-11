clc;
clear_workspace_connect_instruments;
n5183b_toggle_output(keysight_sg,'on');
n5183b_set_frequency(keysight_sg,5750e6);
n5183b_set_amplitude(keysight_sg,-15);
novatech_set_phase(novatech,0,0);
novatech_set_freq(novatech,30,0);
novatech_set_phase(novatech,0,1);
novatech_set_freq(novatech,30,1);
%  [a, b, c]=novatech_readout_settings(novatech,0)
%  [a, b, c]=novatech_readout_settings(novatech,1)

% f = 5749e6:1e5:5751e6;
f = 5740e6:1e6:5760e6;
p = zeros(1,length(f));
for i = 1:length(f)
    p(i)=findBestPhase(keysight_sg, lockin_sr844, f(i));
end
f,p
plot(f,p)

function [best] = findBestPhase(keysight_handle,lockin_handle, freq)
    n5183b_set_frequency(keysight_handle,freq);
    temp  = findGoodPhase(lockin_handle,0:10:180);
    temp2 = findGoodPhase(lockin_handle,(temp-10):1:(temp+10));
    temp3 = findGoodPhase(lockin_handle,(temp-1):0.1:(temp+1));
    best = temp2;
end

function [good] = findGoodPhase(lockin_handle, a)
    len = length(a);
    b = zeros(1,len);
    for i = 1:len
        b(i) = measureX(lockin_handle, a(i));
    end
    good = a(findMinima(b));
end

function [X] = measureX(lockin_handle, degree)
    sr844_lockin_set_ref_phase_degs(lockin_handle,degree);
    pause(3);
    X = abs(sr844_lockin_query_measured_value(lockin_handle,'X'));
end

function [smallest] = findMinima(a)
    len = length(a);
    b = zeros(1,len);
    b(1) = a(len)+a(1)+a(2);
    for i = 2: len-1
        b(i) = a(i-1)+a(i)+a(i+1);
    end
    b(len) = a(len-1)+a(len)+a(1);
    smallest = find(b==min(b(:)));
end