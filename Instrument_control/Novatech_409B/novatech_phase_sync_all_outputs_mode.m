function[] = novatech_phase_sync_all_outputs_mode(novatech_handle)
% each time any output is changed, every output is phase synced. might
% cause time discontinuity at the moment of setting
    writeline(novatech_handle, 'M a')
end
