function [C_sigma] = calculate_c_sigma_from_Ec(Ec)   %Ec in GHz, C_sigma in aF
   h=6.626e-34;
   e=1.6e-19;
   Ec = h*Ec*1e9;
   C_sigma=e^2/2/Ec;
   C_sigma = C_sigma/1e-18;  %in aF
end