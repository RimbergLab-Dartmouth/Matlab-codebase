function[] = novatech_set_io_mode_to_auto(novatech_handle)
   % will send all I/O updates immediately upon the issue of each command
    writeline(novatech_handle, 'I a')
end