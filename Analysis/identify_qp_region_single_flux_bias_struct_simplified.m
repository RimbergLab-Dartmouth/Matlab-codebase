function [resonance_freqs_no_qp,gate_values_no_qp]=identify_qp_region_single_flux_bias_struct_simplified(resonance_freqs,gate_values)
     
    %%%% this is a simplified version of
    %%%% identify_qp_region_single_flux_bias_struct which directly ask for
    %%%% qp indicies to be deleted
    elm = input('enter an array of indices to be deleted (odd bands and bands without enough data points)');
    gate_values_qp = gate_values(elm);
    resonance_freqs_qp = resonance_freqs(elm);
    gate_values(elm) = [];
    resonance_freqs(elm) = [];
    gate_values_no_qp = gate_values;
    resonance_freqs_no_qp = resonance_freqs;
    
    figure
    fig_1 = plot(gate_values_no_qp,resonance_freqs_no_qp,'o','DisplayName','even band');
    hold on
    plot(gate_values_qp,resonance_freqs_qp,'x','DisplayName','odd band');
    legend show
    
    pause
    close all
     
end