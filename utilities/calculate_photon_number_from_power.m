function[number_cavity_photons]=calculate_photon_number_from_power(Pin_dBm,attenuation) 
    kext = 1.5e6;
    kint = .3e6;
    ktot = kext + kint;
    Pin = 10^((Pin_dBm - attenuation)/10)/1000;
    hbar = 1.05457e-34;
    w0 = 5.784e9;
    number_cavity_photons = 4 *kext*Pin/(hbar*w0*ktot^2);
end