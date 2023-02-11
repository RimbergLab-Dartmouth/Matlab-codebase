function [Ec]=calculate_Ec_from_c_sigma(C_sigma)   %Ec in GHz, C_sigma in aF
   h=6.626e-34;
   e=1.6e-19;
   Ec=e^2/2/C_sigma/1e-18;
   Ec=Ec/h/1e9;
end