function [] = Query_instrument_id(instrument_handle)

query(instrument_handle, '*IDN?')

end

