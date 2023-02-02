function[wide_reserve_mode] = sr844_lockin_query_wide_reserve_mode(lockin_handle)
  % reserve_mode = 'high', 'norm', 'low'
    wide_reserve_mode = query(lockin_handle, 'WRSV?');
    if wide_reserve_mode == 0
        wide_reserve_mode = 'high';
    elseif wide_reserve_mode == 1
        wide_reserve_mode = 'norm';
    elseif wide_reserve_mode == 2
        wide_reserve_mode = 'low';
    end
    
end