function [] = n9000_set_detector_type(sa_handle, detector_type)
    %detector types : 'norm'(clear write), 'Aver', 'pos' (peak), 
    %'neg' (peak), 'RMS', 'samp'
    fprintf(sa_handle, [':Detector:trace ' detector_type])
end
