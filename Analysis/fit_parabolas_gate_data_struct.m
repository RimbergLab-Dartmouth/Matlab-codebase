function [gate_offset, gate_period, vertex_offset, concavity, freqs_theory_complete,goodness_fit] = fit_parabolas_gate_data_struct(gate_bias, res_freqs, approx_number_periods)
   
%%%%%%% concavity sign finder
% since res freqs cluster around the vertex of the parabola, use
% histogramming to gauge whether the gauge is at the max range of res freqs
% or closer to the min range, hence determining concavity +/-
    h = histogram(res_freqs,3);
    counts = h.Values;
    bin_edges = h.BinEdges;
    [~, max_count_index] = max(counts);
    if max_count_index == 1
        bin_edge_select = bin_edges(1);
    elseif max_count_index == 3
        bin_edge_select = bin_edges(end);
    else
        disp('the res freqs appear to cluster incorrectly.')
        gate_offset = 1;
        gate_period = 1; 
        vertex_offset = 1; 
        concavity = 1;
        freqs_theory_complete = 1;
        goodness_fit = 1e12;
        return
    end
    if abs(min(res_freqs) - bin_edge_select) < abs(max(res_freqs) - bin_edge_select)
        concavity_guess = 3e4;
        [vertex_offset_guess, ~] = min(res_freqs); % vertical offset of vertex
    else
        concavity_guess = -3e4;
        [vertex_offset_guess, ~] = max(res_freqs);
    end
    %%%%%%%%%% 
    
    gate_period_guess = (max(gate_bias) - min(gate_bias));
    [~,gate_index_1st_period_end] = min(abs(gate_bias(1) + gate_period_guess/approx_number_periods - gate_bias));
    res_freqs_temp_values = res_freqs(1:gate_index_1st_period_end);
    [~, gate_offset_guess_index] = min(res_freqs_temp_values);
    gate_offset_guess = gate_bias(gate_offset_guess_index); % horizontal offset of vertex
    
    initial_params=[gate_offset_guess,gate_period_guess,vertex_offset_guess,concavity_guess];
%     [~,~, initial_freqs_theory] = compute_freqs_from_guess(gate_bias, res_freqs,initial_params,approx_number_periods);
%     figure
%     plot(gate_bias, res_freqs,'.')
%     hold on
%     for i = 1:approx_number_periods
%           plot(gate_bias, initial_freqs_theory(i,:))
%         hold on
%         plot(gate_bias,initial_freqs_theory(i,:))
%         title('initial guess plot')
%     end
    options=optimset('MaxIter',10000,'MaxFunEvals',10000,'TolFun',1e-14,'TolX',1e-14);
    err = @(p) compute_freqs_from_guess(gate_bias,res_freqs, p, approx_number_periods);
    [fit_params_temp,goodness_fit,~,~]=fminsearch(err,initial_params,options);
%     disp(['the goodness of the fit was ' num2str(goodness_fit)]);
    gate_offset = fit_params_temp(1);
    gate_period = fit_params_temp(2);
    vertex_offset = fit_params_temp(3);
    concavity = fit_params_temp(4);
    
    [~,freqs_theory_complete] = compute_freqs_from_guess(gate_bias,res_freqs,fit_params_temp,approx_number_periods);
end

function [err,freqs_theory_complete,freqs_theory] = compute_freqs_from_guess(gate_bias, res_freqs, fit_params,approx_number_periods)
    gate_offset_guess = fit_params(1);
    gate_period_guess = fit_params(2);
    vertex_offset_guess = fit_params(3);
    concavity_guess = fit_params(4);
    freqs_theory = zeros(approx_number_periods, length(gate_bias));
    for i = 1:approx_number_periods
        freqs_theory(i,:) = concavity_guess.*(gate_bias - gate_offset_guess - (i - 1) * gate_period_guess).^2 + vertex_offset_guess;
    end
    if concavity_guess > 0
        freqs_theory_complete = min(freqs_theory,[],1);
    elseif concavity_guess < 0 
        freqs_theory_complete = max(freqs_theory,[],1);
    end
    err = mean(abs(res_freqs' - freqs_theory_complete));
end