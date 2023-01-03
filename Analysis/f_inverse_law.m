function [freqs,values_out]=f_inverse_law(freqs,amp,exponent)
    values_out = amp*(1./freqs).^exponent;
end