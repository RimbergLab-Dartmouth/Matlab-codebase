function [kerr_required_MHz] = find_kerr_MHz_ng_flux(ng_value, flux_value)
    
    load(['D:\Academics\E-Books\Dartmouth\Rimberg Lab\Data\Sample Design\' ...
    'kerr_finder\kerr_data_for_jules_sample.mat'], 'gate_values', 'flux_values', 'kerr_MHz');

    ng_value = mod(ng_value,2);
    flux_value = mod(flux_value, 1);
    
    [~, ng_number] = min(abs(ng_value - gate_values));
    [~, flux_number] = min(abs(flux_value - flux_values));
    kerr_required_MHz = kerr_MHz(flux_number, ng_number);    
end