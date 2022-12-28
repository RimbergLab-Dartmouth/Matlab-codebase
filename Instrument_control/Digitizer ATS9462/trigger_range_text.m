function [trigger_range_text_out]=trigger_range_text(trigger_range_value)
    if trigger_range_value==1
        trigger_range_text_out=hex2dec('00000001');
    elseif trigger_range_value==5
        trigger_range_text_out=hex2dec('00000000');
    else
        fprintf('enter valid trigger range')
        return
    end
end