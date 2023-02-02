function[] = sr844_lockin_set_close_reserve_mode(lockin_handle, close_reserve_mode)
  % reserve_mode = 'high', 'norm', 'low'
    if strcmp(close_reserve_mode, 'high')
        close_reserve_mode = 0;
    elseif strcmp(close_reserve_mode, 'norm')
        close_reserve_mode = 1;
    elseif strcmp(close_reserve_mode, 'low')
        close_reserve_mode = 2;
    end
    fprintf(lockin_handle, ['CRSV ' num2str(close_reserve_mode)])
end