function [Rn]=calculate_Rn_given_Ej(Ej)   %Ej in GHz, Rn in Kohms
   h=6.626e-34;
   e=1.6e-19;
   Rk=25.6e3;
   delta=200e-6*e;
   Ej=Ej*h*1e9;
   Rn=1/8*Rk*delta/Ej;
   Rn=Rn/1e3;
end