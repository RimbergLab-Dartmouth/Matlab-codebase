function[] = novatech_set_io_mode_to_wait(novatech_handle)
   % will send all I/O updates upon a command sending a pulse (novatech_io_send_pulse), if and when
   % received, and not until then 
    writeline(novatech_handle, 'I m')
end