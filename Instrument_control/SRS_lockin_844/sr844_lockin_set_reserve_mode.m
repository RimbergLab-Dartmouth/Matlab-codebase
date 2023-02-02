function[] = sr844_lockin_set_wide_reserve_mode(lockin_handle, wide_reserve_mode)
  % reserve_mode = 'high', 'norm', 'low'
    if strcmp(wide_reserve_mode, 'high')
        wide_reserve_mode = 0;
    elseif strcmp(wide_reserve_mode, 'norm')
        wide_reserve_mode = 1;
    elseif strcmp(wide_reserve_mode, 'low')
        wide_reserve_mode = 2;
    end
    fprintf(lockin_handle, ['WRSV ' num2str(wide_reserve_mode)])
end