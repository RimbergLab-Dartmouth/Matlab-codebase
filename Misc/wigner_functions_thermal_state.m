function[]=wigner_functions_thermal_state(omega,temp); %omega in rad/s
q=linspace(-10,10,1000);
p=linspace(-10,10,1000);
h=6.626e-34;
hbar=h/2/pi;
kb=1.38e-23;
[P,Q]=meshgrid(p,q);
wigner=1/pi*tanh(hbar*omega/kb/temp/2)*exp(-(Q.^2+P.^2)*tanh(hbar*omega/kb/temp/2));
figure
s=surf(q,p,wigner);
colormap(jet);
tit3=['wigner function for thermal state omega= ' num2str(omega/1e9) 'GHz and temperature= ' num2str(temp) 'K'];
title(tit3);
xlabel('q');
ylabel('p');
zlabel('W(q,p)');
set(s,'LineStyle','none'); 
