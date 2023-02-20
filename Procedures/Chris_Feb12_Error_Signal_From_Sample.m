clc;
clear_workspace_connect_instruments;
switch_PDH_measurement(keysight_sg, ps_2)
n5183b_toggle_output(keysight_sg,'on')
n5183b_set_amplitude(keysight_sg,-25)
n5183b_set_frequency(keysight_sg, 5.7845e9)

% [a, b, c] = novatech_readout_settings(novatech, 0)

novatech_set_phase(novatech,0,0);
novatech_set_freq(novatech,30,0);
novatech_set_phase(novatech,0,1);
novatech_set_freq(novatech,30,1);

centerFreq = 5.7845e9;
range = 5;
resolution = 0.1;%MHz
freq = -range:resolution:range;
record = zeros(1,length(freq));
rep = 100;

disp('rough estimate:')
disp(2*range/resolution*(1.5+rep*0.5)/60)
disp('minutes')

for i = 1:length(freq)
    n5183b_set_frequency(keysight_sg, centerFreq+freq(i)*1e6)
    pause(1.5);
    X = abs(sr844_lockin_query_measured_value(lockin_sr844,'X'));
    Y = abs(sr844_lockin_query_measured_value(lockin_sr844,'Y'));
    temp = 0;
    for j = 1:rep
        pause(0.5);
        temp = temp + sqrt(X^2+Y^2)/rep;
    end
    record(i) = temp;
end

freq
record
plot(freq,record)

n5183b_toggle_output(keysight_sg,'off')