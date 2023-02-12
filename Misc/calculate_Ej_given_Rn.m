function [Ej]=calculate_Ej_given_Rn(Rn)   %Ej in GHz, Rn in Kohms (resistance of single junction)
   Rn=Rn*1000;
   h=6.626e-34;
   e=1.6e-19;
   Rk=25.6e3;
   delta=200e-6*e;
   Ej=1/8*Rk*delta/Rn;
   Ej=Ej/h;
   Ej=Ej/1e9;
end