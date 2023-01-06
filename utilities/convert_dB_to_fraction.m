function [fraction] = convert_dB_to_fraction(fraction_in_dB)
    fraction = 10.^(fraction_in_dB./10);
end