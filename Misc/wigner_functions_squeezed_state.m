function[]=wigner_functions_squeezed_state(squeezing_parameter);
q=linspace(-3,3,1000);
p=linspace(-15/squeezing_parameter,15/squeezing_parameter,1000);
wigner=ones(length(p),length(q));
[P,Q]=meshgrid(p,q);
wigner=1/pi*exp(-(exp(2*squeezing_parameter).*Q).^2-(exp(-2*squeezing_parameter).*P).^2);
figure
s=surf(q,p,wigner);
colormap(jet);
tit3=['wigner function for squeezing parameter=  ' num2str(squeezing_parameter)];
title(tit3);
xlabel('q');
ylabel('p');
zlabel('W(q,p)');
set(s,'LineStyle','none'); 
