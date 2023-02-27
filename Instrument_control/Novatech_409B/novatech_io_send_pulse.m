function[] = novatech_io_send_pulse(novatech_handle)
   % will send I/O pulse with all commands since last send 
    writeline(novatech_handle, 'I p')
end