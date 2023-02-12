time = 0:1/168e6:50e-6 - 1/168e6;
sin_wave = 3*sin(2*pi*21e6*time);
figure

for i = 1:length(time)/71
    [amp(i,1:63), phase(i,1:63), x(i,1:63), p(i,1:63)] = get_amp_and_phase(time((i-1)*71 + 1: i*71), sin_wave((i-1)*71 + 1: i*71), 21e6,168e6);
    if i < 3
        hold on
        plot(time((i-1)*71 + 1: i*71) - time((i-1)*71 + 1), sin_wave((i-1)*71 + 1: i*71))
    end
end
