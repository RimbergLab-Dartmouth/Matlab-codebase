function[message] = novatech_set_phase(novatech_handle, phase_in_degs, channel_number)
% amplitude from 0V to +1Vpp, channel number : 0 to 3
    if wrapTo360(phase_in_degs) == 360
        phase_in_degs = 0;
    end
    phase_in_10_bit = round(wrapTo360(phase_in_degs)/360 * 16383);
    message = ['P' num2str(channel_number) ' ' num2str(phase_in_10_bit)];
    writeline(novatech_handle, message)
end