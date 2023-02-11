omega_start = 5.7e9;
omega_stop = 5.782e9;
omega_spacing = .1e6;
omega_0 = 5.76e9;
kappa_int = 0.2e6;
kappa_ext = 1.5e6;
omega_m = 3e7;

omega_c = omega_start : omega_spacing : omega_stop;
omega_c_plus_m = omega_start + omega_m : omega_spacing : omega_stop + omega_m;
omega_c_minus_m = omega_start - omega_m : omega_spacing : omega_stop - omega_m;

[s11_omega_c_real, s11_omega_c_imag] = q_circle(omega_c, kappa_int, kappa_ext, omega_0);
[s11_omega_c_plus_m_real, s11_omega_c_plus_m_imag] = q_circle(omega_c_plus_m, kappa_int, kappa_ext, omega_0);
[s11_omega_c_minus_m_real, s11_omega_c_minus_m_imag] = q_circle(omega_c_minus_m, kappa_int, kappa_ext, omega_0);

s11_omega_c = s11_omega_c_real + 1i.*s11_omega_c_imag;
s11_omega_c_plus_m = s11_omega_c_plus_m_real + 1i.* s11_omega_c_plus_m_imag;
s11_omega_c_minus_m = s11_omega_c_minus_m_real + 1i.* s11_omega_c_minus_m_imag;

error_signal = s11_omega_c .* conj(s11_omega_c_plus_m) - conj(s11_omega_c) .* s11_omega_c_minus_m;

figure
plot((omega_c - omega_0)/omega_m, real(error_signal))
xlabel('$\frac{(\omega_c - \omega_0)}{\omega_m}$', 'interpreter', 'latex')
ylabel('Re(Error signal)', 'interpreter', 'latex')
figure
plot((omega_c - omega_0)/omega_m, imag(error_signal))
xlabel('$\frac{(\omega_c - \omega_0)}{\omega_m}$', 'interpreter', 'latex')
ylabel('Imag(Error signal)', 'interpreter', 'latex')
figure
plot(real(error_signal), imag(error_signal))
xlabel('Re(Error signal)', 'interpreter', 'latex')
ylabel('Imag(Error signal)', 'interpreter', 'latex')
