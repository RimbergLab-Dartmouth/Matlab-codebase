function[]=vna_set_power(vna_handle,power,channel_number,units)
     if ~exist('channel_number','var')
        channel_number=str2double(query(vna_handle,':serv:chan:act?'));
     end 
     if ~exist('units','var')
         units='dBm';
     end
     if strcmpi(units,'dBm')
         power_dBm=power;
     end
     if strcmpi(units,'Watts') | strcmpi(units,'W')
         power_dBm=10*log10(power/1e-3);
     end
     if strcmpi(units,'Vpp')
         power_watts=power^2/400;
         power_dBm=10*log10(power_watts/1e-3);
     end
     if strcmpi(units,'Vp')
         power_watts=power^2/100;
         power_dBm=10*log10(power_watts/1e-3);
     end
     if strcmpi(units,'Vrms')
         power_watts=power^2/50;
         power_dBm=10*log10(power_watts/1e-3);
     end
     fprintf(vna_handle,[':sour' num2str(channel_number) ':pow ' num2str(power_dBm)]);
end
     