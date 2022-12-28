function []=tds_toggle_auto_trigger(tds_handle,auto_trigger_state)
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    clear tds_handle
    tds_handle=gpib('ni',0,address,'InputBuffer',200000*1024,'OutputBuffer',2000*1024);
    fopen(tds_handle)
    if auto_trigger_state=1
        state='auto';
    else 
        auto_trigger_state=0
        state='norm';
    end
    fprintf(tds_handle,['trig:a:mod ' state]);  
    fclose(tds_handle)
    delete(tds_handle)
end
