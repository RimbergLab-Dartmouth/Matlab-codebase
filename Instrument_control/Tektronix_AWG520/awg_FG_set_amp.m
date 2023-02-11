function [] = awg_FG_set_amp(awg_handle, amp, channel_number, units)
% amp between 0.02Vpp to 2.000 Vpp
    if ~exist('units', 'var')
        units = 'Vpp';
    end
    if strcmp(units, 'Vpp')
        amp_to_set = amp;
    elseif strcmp(units, 'Vp')
        amp_to_set = amp * 2;
    elseif strcmp(units, 'dBm')
        amp_to_set = 2*convert_dBm_to_Vp(amp);
    end
    if amp_to_set < 0.02
        disp('cannot set any lower. setting at minimum amplitude of 0.02 Vpp')
        amp_to_set = 0.02;
    end
    if amp_to_set > 2
        disp('cannot set any higher. setting at maximum amplitude of 2 Vpp')
        amp_to_set = 2;
    end
    fprintf(awg_handle, ['awgc:FG' num2str(channel_number) ':Volt ' num2str(amp_to_set)])
    
end

