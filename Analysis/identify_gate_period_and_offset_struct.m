function[gate_period,gate_offset,vertex_offsets, concavity]=identify_gate_period_and_offset_struct(resonance_freqs,resonance_freqs_no_qp,flux_values,gate_values,center_freq,number_even,display_plots)

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~exist ('display_plots','var')
        display_plots=0;
    end

    res_freqs = resonance_freqs;
    res_freqs(resonance_freqs_no_qp == 0) = 0;
    gate_test = gate_values;
    gate_test(res_freqs == 0) = [];
    res_freqs(res_freqs == 0) = [];
    [gate_offsets, gate_periods, vertex_offsets, concavity, freqs_theory_complete, goodness_fit] = fit_parabolas_gate_data_struct(gate_test, res_freqs, number_even);

    theory_freqs = freqs_theory_complete;
    theory_freqs(theory_freqs == 0) = center_freq;

    figure
    plot(gate_test, res_freqs,'o', 'displayName', 'data freqs')
    hold on
    plot(gate_test, theory_freqs,'x', 'displayName', 'theory freqs')
    legend show
    disp(['fit error was ' num2str(goodness_fit)])
    disp(['the input gate period is ' num2str(gate_periods/10) 'V and the offset is ' num2str(gate_offsets/10) ' V'])
    user=input('does this gate period and gate offset seem reasonable?. 0/1'); 
        if user == 1
            gate_period = gate_periods;
            gate_offset = gate_offsets;
            close all;
            figure
            plot((gate_values - gate_offset)/gate_period*2,resonance_freqs,'o');
            xlabel('gate number of electrons')
            ylabel(['res freqs for flux ' num2str(flux_values)])
            title('shifted res freqs as a function of gate number of electrons')
            user=input('hit enter to continue'); 
            close 
        elseif user == 0
            gate_period =  input('enter the period (in mV)');
            gate_offset = input('enter the offset (in mV)');
        end
end
    

