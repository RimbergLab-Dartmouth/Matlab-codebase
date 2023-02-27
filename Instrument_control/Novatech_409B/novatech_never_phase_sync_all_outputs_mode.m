function[] = novatech_never_phase_sync_all_outputs_mode(novatech_handle)
% each time any output is changed, phase register is not cleared. no
% discontinuity in time for any individual output, but relative phases
% between outputs might be changed
    writeline(novatech_handle, 'M n')
end
