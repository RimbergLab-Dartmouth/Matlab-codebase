function[]=wigner_function_cat_state(amplitude);
q=linspace(-1.5*amplitude,1.5*amplitude,1000);
p=linspace(-2,2,1000);
wigner=ones(length(p),length(q));
[P,Q]=meshgrid(p,q);
wigner=exp(-(Q-amplitude).^2-P.^2)+exp(-(Q+amplitude).^2-P.^2)+2.*exp(-Q.^2-P.^2).*cos(2.*P*amplitude);
figure
s=surf(q,p,wigner);
colormap(jet);
tit3=['wigner function for amplitude of q0= ' num2str(amplitude)];
title(tit3);
xlabel('q');
ylabel('p');
zlabel('W(q,p)');
set(s,'LineStyle','none'); 
