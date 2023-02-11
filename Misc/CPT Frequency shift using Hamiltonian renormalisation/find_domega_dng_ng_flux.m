function [domega_dng_reqd]= find_domega_dng_ng_flux(ng_value, flux_value)
    
    load('useful_domega_dng_values_jules_sample.mat', 'gate_values_1', 'flux_values_1', 'domega_dng');

    ng_value = mod(ng_value,2);
    flux_value = mod(flux_value, 1);
    
    %%% select required epsilon from mat file %%%%
    [~, ng_number] = min(abs(ng_value - gate_values_1));
    [~, flux_number] = min(abs(flux_value - flux_values_1));
    domega_dng_reqd = domega_dng(flux_number, ng_number); % in Hz
end