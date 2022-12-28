function [range_code]=input_range_text_ATS(input_value)
    if input_value== .2
        range_code=hex2dec('00000006');
    elseif input_value==.4
        range_code=hex2dec('00000007');
    elseif input_value==.8
        range_code=hex2dec('00000008');
    elseif input_value==2
        range_code=hex2dec('0000000B');
    elseif input_value==4
        range_code=hex2dec('0000000C');
    else
        range_code='invalid';
    end  
end