function [err,theory_flux,theory_gate] = resonance_freqs_error_calc_struct(resonance_freqs_no_qp,flux_values,gate_values,fit_params, number_charge_states)
    if ~exist('number_charge_states', 'var')
        number_charge_states = 9;
    end
    f0=fit_params(1);
    Ej=fit_params(2);
    Ec=fit_params(3);
    resonance_freqs_no_qp(resonance_freqs_no_qp == 0) = 3e12;
    if f0<min(min(resonance_freqs_no_qp))
        err=1e15;
        disp('center freq too low')
        f0
        return
    end
    resonance_freqs_no_qp(resonance_freqs_no_qp == 3e12) = 0;
    if f0>max(max(resonance_freqs_no_qp))
        err=1e15;
        disp('center freq too high')
        f0
        return
    end
    if Ej<1e9
        err=1e15;
        disp('Ej too low')
        Ej
        return
    end
    if Ej>1e11
        err=1e15;
        disp('Ej too high')
        Ej
        return
    end
    if Ec>1e11
        err=1e15;
        disp('Ec too high')
        Ec
        return
    end
    if Ec<1e9
        err=1e15;
        disp('Ec too low')
        Ec
        return
    end
    [freq_shift]=eigenvalues_v1_3_struct(Ej,Ec,number_charge_states,flux_values,gate_values,0,6);
    theory_res_freqs=f0+freq_shift; 
    theory_res_freqs(resonance_freqs_no_qp==0)=mean(mean(theory_res_freqs));
%     figure
%     surf(gate_values, flux_values, theory_res_freqs/1e9)
%     colorbar
%     title(['E_J = ' num2str(Ej/1e9) 'GHz, E_C = ' num2str(Ec/1e9) 'GHz'], 'interpreter', 'latex')
%     view(0,90)
%     pause
%     close all
%     [row,col]=find(resonance_freqs_no_qp==0);
%     for i=1:length(row)
%         theory_res_freqs(col(i),row(i))=mean(mean(theory_res_freqs));
%     end
%     figure
%     s=surf(flux_values,gate_values,theory_res_freqs');
%     title('theory freqs')
%     axis([flux_values(1) flux_values(end) gate_values(1) gate_values(end) 5.6e9 5.85e9]);
%     colorbar
%     view(0,90)
%     pause(3)
%     for i=1:length(row)
%         theory_res_freqs(col(i),row(i))=0;
%     end
    theory_res_freqs(resonance_freqs_no_qp==0)=0;
    error_matrix=abs(theory_res_freqs-resonance_freqs_no_qp);
    error_matrix(resonance_freqs_no_qp==0)=[];
%     max(max(error_matrix))
    err=mean(mean(error_matrix));
    close 
end
