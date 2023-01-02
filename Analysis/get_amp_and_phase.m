function [rf_data,rf_phase,x,p]=get_amp_and_phase(t_data,amp_data,if_freq,samp_rate)
   number_samples=floor(samp_rate/if_freq);
   x_waveform=amp_data.*cos(2*pi*if_freq.*t_data);
   p_waveform=amp_data.*sin(2*pi*if_freq.*t_data);
   convolution_array=ones(number_samples,1);
   
   x=2/number_samples.*conv(x_waveform,convolution_array, 'same');
   p=2/number_samples.*conv(p_waveform,convolution_array, 'same');
   
   rf_amp=sqrt(x.^2+p.^2);
   rf_phase=atan2(x,p);
   rf_data=rf_amp';
   rf_phase=rf_phase';
%    rf_data(1:number_samples-1)=[];
%    rf_phase(1:number_samples-1)=[];
%    rf_data(end - number_samples +1 : end) = [];
%    rf_phase(end - number_samples +1 : end) = [];
%    x(1:number_samples-1)=[];
%    p(1:number_samples-1)=[];
%    x(end - number_samples +1 : end) = [];
%    p(end - number_samples +1 : end) = [];
end

