kappa_ext = 5e6;
kappa_int = 0e6;
kappa_tot = kappa_int + kappa_ext;
% kerr = 0.5e6;
kerr = 0;
n_in = 100000; %input power in number photons at input capacitor
cavity_occupation = 4 * kappa_ext * n_in / kappa_tot^2;
detuning = 0e6; % \omega_0 - \omega_p / 2

epsilon = 0;
% epsilon = kappa_ext *.2; % parametric pump drive
freqs = linspace(- 10 * kappa_tot, 10 * kappa_tot, 1000);

% spectrum_out = (n_in .*( - (abs(epsilon))^2 * kappa_ext^2 + (kappa_tot^2/4 + (freqs + (detuning + kerr*cavity_occupation)).^2 ...
%     - (abs(epsilon))^2 - kappa_ext*kappa_tot/2).^2 + kappa_ext^2*(freqs + (detuning + kerr*cavity_occupation)).^2)) ./ (kappa_tot^2/4 + ...
%     (freqs + (detuning + kerr*cavity_occupation)).^2 - (abs(epsilon))^2) ...
%     - ((abs(epsilon))^2 *kappa_ext^2)./(kappa_tot^2/4 + (freqs + (detuning + kerr*cavity_occupation)).^2 - (abs(epsilon))^2);

% spectrum_out = n_in.*((kappa_tot^2/4) + (freqs - (detuning + kerr*cavity_occupation)).^2 - (abs(epsilon))^2 - kappa_ext *(kappa_tot/2 - 1i .*( freqs - (detuning + kerr*cavity_occupation)))) .* ...
%     ((kappa_tot^2/4) + (freqs + detuning + kerr*cavity_occupation).^2 - (abs(epsilon))^2 - kappa_ext*(kappa_tot/2 - 1i.*(freqs + detuning + kerr*cavity_occupation)))./ ...
%     ((kappa_tot^2/4) - (abs(epsilon))^2 + (freqs  - (detuning + kerr*cavity_occupation)).^2) ./ ((kappa_tot^2/4) - (abs(epsilon))^2 + (freqs + detuning + kerr*cavity_occupation).^2) - ...
%     (abs(epsilon))^2 * kappa_ext^2./ ((kappa_tot^2/4) + (freqs - (detuning + kerr*cavity_occupation)).^2 - (abs(epsilon))^2) ./ ((kappa_tot^2/4) - (abs(epsilon))^2 + (freqs + detuning + kerr*cavity_occupation).^2);

% spectrum_out = (1./((kappa_tot /2 - 1i.*freqs).^2 + (detuning + kerr*cavity_occupation)^2 - (abs(epsilon))^2)./((kappa_tot/2 + 1i.*freqs).^2 + (detuning + kerr*cavity_occupation)^2 - (abs(epsilon))^2)) .* ...
%     ((n_in + 1)*(abs(epsilon))^2*kappa_ext^2 + n_in *((kappa_tot/2 - 1i.*freqs).^2 + (detuning + kerr * cavity_occupation)^2 - (abs(epsilon))^2 - kappa_ext * kappa_tot /2 + 1i*kappa_ext.*(freqs - (detuning + kerr*cavity_occupation))) .* ...
%     ((kappa_tot + 1i.*freqs).^2 + (detuning + kerr*cavity_occupation)^2 - (abs(epsilon))^2 - kappa_ext*kappa_tot/2 - 1i*kappa_ext.*(freqs - (detuning + kerr*cavity_occupation))));

spectrum_out = (n_in*(kappa_tot^2/4 + freqs.^2 + (abs(epsilon))^2) + (abs(epsilon))^2 *kappa_ext^2*(n_in +1))./(((kappa_tot/2 - 1i.*freqs).^2 - (abs(epsilon))^2).*((kappa_tot/2 + 1i.*freqs).^2 - (abs(epsilon))^2));
spectrum_out_epsilon_0 = n_in./(kappa_tot^2/4 + freqs.^2);

figure
plot(freqs/1e6, abs(spectrum_out)/n_in)
hold on
plot(freqs/1e6, abs(spectrum_out_epsilon_0/n_in))
xlabel('Detuning (MHz)')
ylabel('S11')
title(['S11 for \kappa_{ext} = ' num2str(kappa_ext/1e6) 'MHz, \kappa_{tot} = ' num2str(kappa_tot/1e6) 'MHz, Kerr = ' num2str(kerr/1e6) 'MHz, cavity occupation = ' num2str(cavity_occupation) ' photons, pump parameter = ' ...
    num2str(epsilon/1e6) 'MHz, detuning = \omega_0 - \omega_p/2 = ' num2str(detuning/1e6) 'MHz'])