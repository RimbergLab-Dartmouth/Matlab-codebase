function[]=wigner_functions_coherent_state(amplitude_q,amplitude_p);
if amplitude_q==0 
        q=linspace(-3,3,1000);
        p=linspace(-3,3,1000);
else
    q=linspace(-1.5*amplitude_q,1.5*amplitude_q,1000);
    p=linspace(-1.5*amplitude_p,1.5*amplitude_p,1000);
end
wigner=ones(length(p),length(q));
[P,Q]=meshgrid(p,q);
wigner=1/pi*exp(-(Q-amplitude_q).^2-(P-amplitude_p).^2);
figure
s=surf(q,p,wigner);
colormap(jet);
tit3=['wigner function for amplitude of q0= ' num2str(amplitude_q) 'and p0= ' num2str(amplitude_p)];
title(tit3);
xlabel('q');
ylabel('p');
zlabel('W(q,p)');
set(s,'LineStyle','none'); 
