function [trigger_external_enable_code]=trig_external_text(trigger_external_value)
    if trigger_external_value==1
        trigger_external_enable_code=hex2dec('00000002');
    elseif trigger_external_value==0
        trigger_external_enable_code=hex2dec('00000000');
    else
        fprintf('choose a valid parameter for trigger external enabling')
    end
end