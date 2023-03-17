function [epsilon_required_MHz, flux_pump_amp_at_sample_in_quanta] = find_epsilon_MHz_ng_flux(ng_value, flux_value, flux_pump_power_dB_at_room_temp)
    
    load(['D:\Academics\E-Books\Dartmouth\Rimberg_Lab\Data\Sample Design\' ...
    'epsilon_finder\domega_dphi_data_for_jules_sample.mat'], 'gate_values', 'flux_values', 'domega_dphi_MHz');

    ng_value = mod(ng_value,2);
    flux_value = mod(flux_value, 1);
    flux_period_Jules_sample = 49.71e-6; %Amps
    flux_line_fridge_attenuation = 80; %dB   %%% might be 86dB based on ben's email.
    flux_pump_power_at_sample = flux_pump_power_dB_at_room_temp - flux_line_fridge_attenuation;
    voltage_amp_at_sample_flux_line = convert_dBm_to_Vp(flux_pump_power_at_sample);
    resistance_across_flux_line_at_sample = 50; % ohms
    current_through_flux_line = voltage_amp_at_sample_flux_line/resistance_across_flux_line_at_sample;
    flux_pump_amp_at_sample_in_quanta = current_through_flux_line/flux_period_Jules_sample;

    %%% select required epsilon from mat file %%%%
    [~, ng_number] = min(abs(ng_value - gate_values));
    [~, flux_number] = min(abs(flux_value - flux_values));
    epsilon_required_MHz = domega_dphi_MHz(flux_number, ng_number)*2*pi;  % multiply by 2*pi since phi is in units of 2*pi in mat file (and in freq shift code)
    epsilon_required_MHz = 0.5 * epsilon_required_MHz * flux_pump_amp_at_sample_in_quanta;

end