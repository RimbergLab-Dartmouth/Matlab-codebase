function [resonance_freqs_no_qp,gate_values_no_qp]=identify_qp_region_single_flux_bias_struct(resonance_freqs,gate_values, number_odd, start_even_or_odd)
     
    %%%% the premise of this program is that there is a big jump in
    %%%% resonance freq when moving from even to odd band. It first
    %%%% identifies the jump points based on the entered number of even and
    %%%% odd bands, and sorts the resonance freqs in two bands accordingly

    %%% get rid of large gate values, since difference between res freqs
    %%% for these values is usually large, and might be mistaken to be a
    %%% jump from odd to even.
    cutoff_freq = 5.798e9;
    gate_values(resonance_freqs > cutoff_freq) = [];
    resonance_freqs(resonance_freqs > cutoff_freq) = [];
    
    %%%% find the big jump indices
     difference=abs(diff(resonance_freqs));
     [~,big_jump_indices] = maxk(difference,(number_odd + 1)*2);  % find a few extra big jumps, in case some of them are close to each other and eliminated
     %%%% if big jump indices are indicated to be next to each other, that
     %%%% cannot be right. 
     big_jump_indices = sort(big_jump_indices);
     eliminate_indices = abs(diff(big_jump_indices));
     big_jump_indices(eliminate_indices<2) = [];
%      if any(big_jump_indices == 1) || any(big_jump_indices == length(resonance_freqs))
%         big_jump_indices = big_jump_indices(1 : min(length(big_jump_indices),number_odd*2 + 1));
%      else
     big_jump_indices = big_jump_indices(1 : min(length(big_jump_indices),number_odd*2));
%      end
     
     if mod(length(big_jump_indices), 2) == 1
         if start_even_or_odd == 0 && ~any(big_jump_indices == length(resonance_freqs))
            big_jump_indices = [big_jump_indices; length(resonance_freqs)];
         elseif start_even_or_odd == 1 && ~any(big_jump_indices == 1)
            big_jump_indices = [0; big_jump_indices];
         end
     end
     qp_freqs = zeros(1,length(resonance_freqs));
     resonance_freqs_no_qp = resonance_freqs;

     for i = 1 : number_odd
         qp_freqs (big_jump_indices(2*i-1)+1:big_jump_indices(2*i)) = resonance_freqs(big_jump_indices(2*i-1)+1:big_jump_indices(2*i));
         resonance_freqs_no_qp(big_jump_indices(2*i-1)+1:big_jump_indices(2*i)) = 0;
     end
     gate_values_no_qp = gate_values;
     gate_values_qp = gate_values;
     gate_values_qp(qp_freqs == 0) = [];
     qp_freqs(qp_freqs == 0) = [];
     gate_values_no_qp(resonance_freqs_no_qp == 0) = [];
     resonance_freqs_no_qp(resonance_freqs_no_qp == 0) = [];
     figure
     fig_1=plot(gate_values_no_qp,resonance_freqs_no_qp,'o','DisplayName','even band');
     hold on
     plot(gate_values_qp,qp_freqs,'x','DisplayName','odd band');
     legend show
     user=input('does this omission of qp region seem reasonable? omitted region is red crosses. 0/1');
     close 
     if user == 1
         return
     elseif user == 0 
         resonance_freqs_no_qp = zeros(1,length(resonance_freqs));
         qp_freqs = resonance_freqs;
         for i = 1:number_odd
             resonance_freqs_no_qp (big_jump_indices(2*i-1)+1:big_jump_indices(2*i)) = resonance_freqs(big_jump_indices(2*i-1)+1:big_jump_indices(2*i));
             qp_freqs(big_jump_indices(2*i-1)+1:big_jump_indices(2*i)) = 0;
         end
         gate_values_no_qp = gate_values;
         gate_values_qp = gate_values;
         gate_values_qp(qp_freqs == 0) = [];
         qp_freqs(qp_freqs == 0) = [];
         gate_values_no_qp(resonance_freqs_no_qp == 0) = [];
         resonance_freqs_no_qp(resonance_freqs_no_qp == 0) = [];
         figure
         fig_2=plot(gate_values_no_qp,resonance_freqs_no_qp,'o','DisplayName','even band');
         hold on
         plot(gate_values_qp,qp_freqs,'x','DisplayName','odd band');
         legend show
         user=input('does this omission of qp region seem reasonable? omitted region is red crosses. 0/1');
         if user == 1
             return
         elseif user == 0
             close
             qp_free_indices = input('enter array of indices below the red cutoff line which are in the odd bad that will be deleted');
             resonance_freqs_no_qp = resonance_freqs;
             gate_values_no_qp = gate_values;
             size(resonance_freqs_no_qp)
             gate_values_no_qp(qp_free_indices) = [];
             resonance_freqs_no_qp(qp_free_indices) = [];
             figure
             fig_2=plot(gate_values_no_qp,resonance_freqs_no_qp,'o','DisplayName','even band');
             legend show
             
         end
     end
     pause
     close all
     
end