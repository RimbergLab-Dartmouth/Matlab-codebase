function[]=awg_combine_source(awg_handle,source)
    
    if ~exist('source', 'var')
        fprintf(awg_handle,[':COMB:FEED ""']);
        return
    end
    
    if strcmp(source, 'int_noise')
        fprintf(awg_handle,[':COMB:FEED "SOURce7"']);
    elseif strcmp(source, 'ext_port')
        fprintf(awg_handle,[':COMB:FEED "SOURce8"']);
    elseif strcmp(source, 'none')
        fprintf(awg_handle,[':COMB:FEED ""']);
    end
    
end