function [filtered_signal, sosbp, gbp] = second_order_chebyshev_filter(data, sampling_freq, pass_band_start, pass_band_stop, steepness, pass_band_ripple, stop_band_ripple)
    % from https://www.mathworks.com/matlabcentral/answers/361348-how-i-applly-a-bandpass-filter-in-a-signal
    if ~exist('steepness', 'var')
        steepness = 1;
    end
    if ~exist('pass_band_ripple','var')
        pass_band_ripple = 1;          %dB
    end
    if ~exist('stop_band_ripple','var')
        stop_band_ripple = 150;         %dB
    end
    
	Fn = sampling_freq/2;                                                  % Nyquist Frequency (Hz)
    
    if steepness >.99
        width_lower = .01 * pass_band_start;
        width_upper = .01 * (Fn - pass_band_stop);
    else
        width_lower = (1 - steepness)*pass_band_start;
        width_upper = (1 - steepness) * pass_band_stop;
    end
    stop_band_lower = pass_band_start - width_lower;
    stop_band_upper = pass_band_stop + width_upper;
    Wp = [pass_band_start   pass_band_stop]/Fn;                                         % Passband Frequency (Normalised)
    Ws = [stop_band_lower   stop_band_upper]/Fn;                                         % Stopband Frequency (Normalised)
    pass_band_ripple =   1;                                                   % Passband Ripple (dB)
    stop_band_ripple = 150;                                                   % Stopband Ripple (dB)
    [n,Ws] = cheb2ord(Wp,Ws,pass_band_ripple,stop_band_ripple);                             % Filter Order
    [z,p,k] = cheby2(n,stop_band_ripple,Ws);                                  % Filter Design
    [sosbp,gbp] = zp2sos(z,p,k);                                % Convert To Second-Order-Section For Stability
%     figure(3)
%     freqz(sosbp, 2^16, sampling_freq)                                      % Filter Bode Plot
    filtered_signal = filtfilt(sosbp, gbp, data);    % Filter Signal
end