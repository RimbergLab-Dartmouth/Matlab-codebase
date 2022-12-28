function []=n5183b_set_amplitude(sg_handle,power,units)
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
     fprintf(sg_handle,[':POW ' num2str(power_dBm) 'DBM' ]);
end
