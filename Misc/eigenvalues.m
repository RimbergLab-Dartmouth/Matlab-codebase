function[]=eigenvalues(Ej,Ec)
% Ej=1.5;  %actually EJ/Ec
L0=2.1966e-9;   %H;
% C0=3.7137e-13;  %F;
C0=3.4793e-13; %Jules' sample
phi0=2.067e-15;
% Ec=42e9; %GHz
Ectemp=Ec;
Ec=6.626e-34*Ec;
gate=linspace(-3,3,350);
% flux=linspace(-2*pi,2*pi,800);
% gate=linspace(-.9,.9,350);
flux=linspace(-pi+.5,pi-.5,800);
for i=1:length(gate)
    for j=1:length(flux)
        charge(:,:,i)=[(-2-gate(i)/2).^2 0 0 0 0
            0 (-1-gate(i)/2).^2 0 0 0
            0 0 (0-gate(i)/2).^2 0 0
            0 0 0 (1-gate(i)/2).^2 0
            0 0 0 0 (2-gate(i)/2).^2];
        
      
        josephson(:,:,j)=[0 -Ej*cos(flux(j)/2) 0 0 0
            -Ej*cos(flux(j)/2) 0 -Ej*cos(flux(j)/2) 0 0
            0 -Ej*cos(flux(j)/2) 0 -Ej*cos(flux(j)/2) 0
            0 0 -Ej*cos(flux(j)/2) 0 -Ej*cos(flux(j)/2)
            0 0 0 -Ej*cos(flux(j)/2) 0];
        
    end
end
charge=repmat(charge,[1 1 1 length(flux) ]);
charge=permute(charge,[1 2 4 3]);
size(charge);
josephson=repmat(josephson,[1 1 1 length(gate)]);
size(josephson);
H=charge+josephson;
size(H)
for i=1:length(gate)
    for j=1:length(flux)
        eigenvalue(:,j,i)=eig(H(:,:,j,i));
        E1(j,i)=eigenvalue(1,j,i);
        E2(j,i)=eigenvalue(2,j,i);
    end
end
flux_array=repmat(flux,length(gate),1)';
dE1=diff(E1)./diff(flux_array);
x=eps*ones(1,length(gate));
dE1=[x; dE1];
dE1squared=diff(dE1)./diff(flux_array);
diff(flux_array);
dE1squared=[x; dE1squared];

Lj=(phi0/2/pi)^2/Ec./dE1squared(2:end,:);
Ltot=Lj.*L0./(Lj+L0);
f=1./sqrt(Ltot*C0)./(2*pi);
f0=1/sqrt(L0*C0)./(2*pi);

figure
s=surf(gate(122:226),flux(3:end),dE1squared(3:end,122:226));
% s=surf(gate(1:end),flux(3:end),dE1squared(3:end,1:end));
tit3=['dE1squared/dphisquared for Ej/Ec=' num2str(Ej)];
title(tit3);
xlabel('gate number of pairs');
ylabel('flux (radians)');
zlabel('dE1squared/dphisquared (units of Ec)');
set(s,'LineStyle','none'); 



figure
% r=surf(gate(1:end),flux(3:end),Lj(2:end,1:end));
r=surf(gate(122:226),flux(3:end),Lj(2:end,122:226));
tit1=['Lj for Ej/Ec=' num2str(Ej)];
title(tit1);
xlabel('gate number of pairs');
ylabel('flux (radians)');
zlabel('Lj (H)');
set(r,'LineStyle','none'); 

if abs(f>1e10)
    f=1e10;
end

figure
% p=surf(gate(1:end),flux(3:end),f(2:end,1:end));
p=surf(gate(122:226),flux(3:end),abs(f(2:end,122:226)));
tit2=['resonant freq for Ej/Ec=' num2str(Ej) 'Ec=' num2str(Ec/6.626e-25) 'GHz'];
title(tit2);
xlabel('number of gate pairs');
ylabel('flux (radians)');
zlabel('f (Hz)');
set(p,'LineStyle','none');

figure
hold on
q=surf(gate,flux,E1);
xlabel('Number of gate Cooper pairs');
ylabel('Flux(radians)');
zlabel('E/Ec');
set(q,'LineStyle','none');
w=surf(gate,flux,E2);
tit=['first two eigenenergies for Ej=' num2str(Ej*Ectemp/1e9) 'GHz Ec=' num2str(Ectemp/1e9) 'GHz'];
title(tit);
set(w,'LineStyle','none'); 
hold off

%%%%%%%%%%%%%%%%5
%troubleshooting
% E1(1,1)
% E2(1,1)
% eigenvalue(1,1,1)
% eigenvalue(2,1,1)
% H(:,:,1,1)
% eig(H(:,:,1,1))
% (1-gate(1)/2)^2
% (2-gate(1)/2)^2
% (3-gate(1)/2)^2
% (4-gate(1)/2)^2
% (5-gate(1)/2)^2
% -Ej*cos(flux(1))
%%%%%%%%%%%%%%%%%%%%