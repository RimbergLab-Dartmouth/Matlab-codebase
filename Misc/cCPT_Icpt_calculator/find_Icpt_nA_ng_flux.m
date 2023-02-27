function [Icpt_required_nA] = find_Icpt_nA_ng_flux(ng_value, flux_value)
    
    load(['D:\Academics\E-Books\Dartmouth\Rimberg Lab\Data\Sample Design\cCPT_Icpt_calculator\Jules_sample_Icpt_vs_flux_gate.mat'], 'gate', 'flux', 'Icpt');

    ng_value = mod(ng_value,2);
    flux_value = mod(flux_value, 1);
    
    %%% select required epsilon from mat file %%%%
    [~, ng_number] = min(abs(ng_value - gate));
    [~, flux_number] = min(abs(flux_value - flux));
    Icpt_required_nA = Icpt(flux_number, ng_number)*1e9;  
end