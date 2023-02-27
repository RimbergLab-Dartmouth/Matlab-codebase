function[message] = novatech_set_amp(novatech_handle, amplitude, channel_number, units)
% amplitude from 0V to +1Vpp, channel number : 0 to 3
    if exist('units', 'var') && strcmp(units, 'dBm')
        amplitude_in_Vpp = 2*convert_dBm_to_Vp(amplitude);
    elseif exist('units', 'var') && strcmp(units, 'Vp')
        amplitude_in_Vpp = 2 * amplitude;
    elseif exist('units', 'var') && strcmp(units, 'Vpp')
        amplitude_in_Vpp = amplitude;
    elseif exist('units', 'var') && ~strcmp(units, 'dBm') && ~strcmp(units, 'Vp') && ~strcmp(units, 'Vpp')
        disp('unrecognized units, options : dBm, Vp or Vpp. If unfilled, Vpp')
    elseif ~exist('units', 'var')
        units = '';
        amplitude_in_Vpp = amplitude;
    end

    amplitude_in_10_bit = round(amplitude_in_Vpp * 1023);
    if amplitude_in_10_bit > 1023
        disp('setting amplitude to max of 1Vpp')
        amplitude_in_10_bit = 1023;
    end
    message = ['V' num2str(channel_number) ' ' num2str(amplitude_in_10_bit)];
    writeline(novatech_handle, message)
end