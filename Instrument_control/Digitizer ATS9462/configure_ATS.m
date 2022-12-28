function [result]=configure_ATS(board_handle,channel_A_range,channel_B_range,...
    trig_external_enable,trig_slope,trig_timeout,trigger_set_point,trig_range,sample_rate)
   %enable values =0/1. if disabled - triggers on channel A, ranges are upper limits (in V), 
   %slope is '+' or '-', trig_range=+1,+5; sample_rates with 10 MHz extrenal clock - see manual
   %trig set point 0 to 255. 127 is 0 V, 255 is trigger range. 
       
   %default values
    channel_A_value=4;
    channel_B_value=4;
    triggerTimeout_sec=0;
    trig_enable_const=0;    
    trig_slope_const='+';
    trig_set_point_const=150;
    trig_range_const=1;
    %%%
    
    if ~exist('sample_rate','var')
        sample_rate=180e6;
    end
    
    if ~exist('channel_A_range','var')
        channel_A_range=channel_A_value; 
    end
    if ~exist('channel_B_range','var')
        channel_B_range=channel_B_value;
    end
    
    if ~exist('trig_external_enable','var')
        trig_external_enable=trig_enable_const;
    end
    
    if ~exist('trig_timeout','var')
        trig_timeout=triggerTimeout_sec;
    end
    
    if ~exist('trig_slope','var')
        trig_slope=trig_slope_const;
    end
    
    if ~exist('trig_set_point','var')
        trigger_set_point=trig_set_point_const;
    end
    
    if ~exist('trig_range','var')
        trig_range=trig_range_const;
    end
    
   
    [trigger_range]=trigger_range_text(trig_range);
    [Trigger_slope_value]=trigger_slope_text(trig_slope);
    [trig_external_code]=trig_external_text(trig_external_enable);
    [channel_A_range_code]=input_range_text_ATS(channel_A_range);
    [channel_B_range_code]=input_range_text_ATS(channel_B_range);
    
    AlazarDefs   % loads the mat file with defns.
    
    result=false;
    
%     % set the board clock  %%
    ret_code=AlazarSetCaptureClock(board_handle,EXTERNAL_CLOCK_10MHz_REF,...     % clock source, rate and edge. 0 is decimation (?)
         sample_rate,CLOCK_EDGE_RISING,0);
%     ret_code = ...
%     AlazarSetCaptureClock(  ...
%         board_handle,        ... % HANDLE -- board handle
%         INTERNAL_CLOCK,     ... % U32 -- clock source id
%         SAMPLE_RATE_180MSPS, ... % U32 -- sample rate id
%         CLOCK_EDGE_RISING,  ... % U32 -- clock edge id
%         0                   ... % U32 -- clock decimation
%         );
    
    if ret_code ~= ApiSuccess
       fprintf('Error: AlazarSetCaptureClock failed -- %s\n', errorToText(ret_code));
       return
    end
    %Channel A
    ret_code=AlazarInputControlEx(board_handle,CHANNEL_A,DC_COUPLING,...
        channel_A_range_code,IMPEDANCE_50_OHM);   % default: DC_coupled, 50 ohm impedance
    
    if ret_code ~= ApiSuccess
         fprintf('Error: AlazarInputControlEx failed -- %s\n', errorToText(ret_code));
         return
    end
    
    ret_code= AlazarSetBWLimit(board_handle,CHANNEL_A,0);  % default: BW limiting disabled
    
    if ret_code ~= ApiSuccess
         fprintf('Error: AlazarSetBWLimit failed -- %s\n', errorToText(ret_code));
         return
    end
    %Channel B
    ret_code=AlazarInputControlEx(board_handle,CHANNEL_B,DC_COUPLING,...
        channel_B_range_code,IMPEDANCE_50_OHM);   % default: DC_coupled, 50 ohm impedance
    
    if ret_code ~= ApiSuccess
         fprintf('Error: AlazarInputControlEx failed -- %s\n', errorToText(ret_code));
         return
    end
    
    ret_code= AlazarSetBWLimit(board_handle,CHANNEL_B,0);  % default: BW limiting disabled
    
    if ret_code ~= ApiSuccess
         fprintf('Error: AlazarSetBWLimit failed -- %s\n', errorToText(ret_code));
         return
    end
    
    %trigger - if external trigger value = 0, automatically switches to
    %triggering on channel A, at the trigger_set_point_value
   ret_code=AlazarSetTriggerOperation(board_handle,TRIG_ENGINE_OP_J,TRIG_ENGINE_J,...
        trig_external_code,Trigger_slope_value,trigger_set_point,TRIG_ENGINE_K,TRIG_DISABLE,...
        TRIGGER_SLOPE_POSITIVE,128);
    
    if ret_code~=ApiSuccess
        fprintf('Error: AlazarSetTriggerOperation failed -- %s\n', errorToText(ret_code));
        return
    end
    
    %External trigger settings
   ret_code=AlazarSetExternalTrigger(board_handle,DC_COUPLING,trigger_range);
    
    if ret_code~=ApiSuccess
        fprintf('Error: AlazarSetExternalTrigger failed --%s\n', errorToText(ret_code));
        return
    end
    
%     % TODO: Set trigger delay as required.
%     triggerDelay_sec = 0;
%     triggerDelay_samples = uint32(floor(triggerDelay_sec * samplesPerSec + 0.5));
%     ret_code = AlazarSetTriggerDelay(boardHandle, triggerDelay_samples);
%     if ret_code ~= ApiSuccess
%         fprintf('Error: AlazarSetTriggerDelay failed -- %s\n', errorToText(ret_code));
%         return;
%     end

    triggerTimeout_clocks=uint32(floor(trig_timeout/10e-6 +0.5));
    ret_code=AlazarSetTriggerTimeOut(board_handle,triggerTimeout_clocks);
    if ret_code~=ApiSuccess
        fprintf('Error: AlazarSetTriggerTimeOut failed -- %s\n', errorToText(ret_code));
        return
    end
    
%         % TODO: Configure AUX I/O connector as required
%     ret_code = ...
%         AlazarConfigureAuxIO(   ...
%             boardHandle,        ... % HANDLE -- board handle
%             AUX_OUT_TRIGGER,    ... % U32 -- mode
%             0                   ... % U32 -- parameter
%             );
%     if ret_code ~= ApiSuccess
%         fprintf('Error: AlazarConfigureAuxIO failed -- %s\n', errorToText(ret_code));
%         return
%     end
   result=true;
end