function[close_reserve_mode] = sr844_lockin_query_close_reserve_mode(lockin_handle)
  % reserve_mode = 'high', 'norm', 'low'
    close_reserve_mode = query(lockin_handle, 'CRSV?');
    if close_reserve_mode == 0
        close_reserve_mode = 'high';
    elseif close_reserve_mode == 1
        close_reserve_mode = 'norm';
    elseif close_reserve_mode == 2
        close_reserve_mode = 'low';
    end
    
end