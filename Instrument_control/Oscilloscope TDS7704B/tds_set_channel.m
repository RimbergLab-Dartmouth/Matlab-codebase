function [] = tds_set_channel(tds_handle,channel)
    address=tds_handle.PrimaryAddress;
    fclose(tds_handle)
    address_string = ['GPIB0::' num2str(address) '::INSTR'];
    clear tds_handle
    tds_handle=visa('ni',address_string);
    tds_handle.InputBufferSize = 200000*1024;
    tds_handle.OutputBufferSize = 2000*1024;
    fopen(tds_handle)
    if ~exist('channel','var')
        channel=query(tds_handle,'data:source?');
    end
    fprintf(tds_handle,['data:source ch' num2str(channel)]);
    fclose(tds_handle)
    delete(tds_handle)
end

