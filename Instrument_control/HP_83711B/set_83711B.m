function[]=set_83711B(HP_handle,frequency,amplitude,output_on)
%output on: 1, output off: 0
% fclose(HP_handle);
if output_on==1
    output=[':outp ' num2str(1)];
else
    output=[':outp ' num2str(0)];
end
% fopen(HP_handle);
frequency_settings=[':sour:freq ' num2str(frequency)];
fprintf(HP_handle,frequency_settings);
power_settings=[':pow ' num2str(amplitude)];
fprintf(HP_handle,power_settings);
fprintf(HP_handle,output);
% fclose(HP_handle);