function [freqs, psd, psd_dbm] = extract_PSD(time, x)
    if diff(time) - mean(diff(time)) > 1e-19
        disp('check time input')
        return
    end
    Fs = 1/diff(time(1:2)); %extract sampling frequency, which is the frequency spacing of the PSD. 
    N = length(x); 
    xdft = fft(x);
    xdft = xdft(1:N/2+1);
    psd = (1/(Fs*N)) * abs(xdft).^2;
    psd(2:end-1) = 2*psd(2:end-1);
    psd_temp = psd;
    psd_temp(psd_temp < 1e-20) = 1e-11;
    psd_dbm = 10*log10(psd_temp);
    freqs = 0:Fs/length(x):Fs/2;
end