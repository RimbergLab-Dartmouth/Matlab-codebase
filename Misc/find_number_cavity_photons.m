function[number_cavity_photons]=find_number_cavity_photons(power_top,attenuation,cavity_decay,res_freq) %power_top in dBm, attenuation in dB assuming on resonance
   if ~exist('cavity_decay','var')
       cavity_decay=1.5e6;
   end
   if ~exist('res_freq','var')
       res_freq=5.76e9;
   end
   h=6.626e-34;
   power_input_cav=power_top-attenuation;
   power_input_cav_watts=10^(power_input_cav/10-3);
   number_cavity_photons=2*power_input_cav_watts/h/res_freq/cavity_decay;
end
