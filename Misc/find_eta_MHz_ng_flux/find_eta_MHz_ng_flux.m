function [eta_required_MHz, flux_pump_amp_at_sample_in_quanta] = find_eta_MHz_ng_flux(ng_value, flux_value, flux_pump_power_dB_at_room_temp)
    
    phi_zp = .176;
    
    ng_value = mod(ng_value,2);
    flux_value = mod(flux_value, 1);
    kerr_MHz = find_kerr_MHz_ng_flux(ng_value, flux_value);    
    
    flux_period_Jules_sample = 49.71e-6; %Amps
    flux_line_fridge_attenuation = 86; %dB
    flux_pump_power_at_sample = flux_pump_power_dB_at_room_temp - flux_line_fridge_attenuation;
    voltage_amp_at_sample_flux_line = convert_dBm_to_Vp(flux_pump_power_at_sample);
    resistance_across_flux_line_at_sample = 50; % ohms
    current_through_flux_line = voltage_amp_at_sample_flux_line/resistance_across_flux_line_at_sample;
    flux_pump_amp_at_sample_in_quanta = current_through_flux_line/flux_period_Jules_sample;
    
    eta_required_MHz = kerr_MHz * pi /phi_zp *flux_pump_amp_at_sample_in_quanta;
      
end