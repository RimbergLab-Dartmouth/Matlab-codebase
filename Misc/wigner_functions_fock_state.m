function[]=wigner_functions_fock_state(fock_number)
q=linspace(-fock_number,fock_number,500);
p=linspace(-fock_number,fock_number,500);
wigner=ones(length(p),length(q));
[P,Q]=meshgrid(p,q);
wigner=(-1)^fock_number/pi*exp(-Q.^2-P.^2).*laguerreL(fock_number,(2.*Q.^2+2.*P.^2));
figure
s=surf(q,p,wigner);
colormap(jet);
tit3=['wigner function for fock state n= ' num2str(fock_number)];
title(tit3);
xlabel('q');
ylabel('p');
zlabel('W(q,p)');
set(s,'LineStyle','none'); 
