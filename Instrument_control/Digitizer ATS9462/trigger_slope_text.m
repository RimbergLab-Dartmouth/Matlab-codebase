function[trigger_slope_code]=trigger_slope_text(trigger_slope_value)
    if strcmp(trigger_slope_value,'+')
        trigger_slope_code=hex2dec('00000001');
    elseif strcmp(trigger_slope_value,'-')
        trigger_slope_code=hex2dec('00000002');
    else 
        fprintf('enter valid trigger slope')
        return
    end
end