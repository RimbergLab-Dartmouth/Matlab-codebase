function[] = novatech_set_clock_source(novatech_handle, clock_source)
% clock source : 'E'(external) or 'I'(internal)
    writeline(novatech_handle, ['C ' clock_source])
end
