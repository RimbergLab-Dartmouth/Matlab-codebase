function[flux_period,flux_offset,center_freq, offset_slope]=identify_flux_period_and_offset_struct(resonance_freqs,flux_values,gate_values,display_plots)

    
    if ~exist ('display_plots','var')
        display_plots=0;
    end
    
    [sin_fit,~,goodness_fit]=fit_sin_struct(flux_values,resonance_freqs);
	sin_fit = sin_fit';
    err(1,1)=goodness_fit;
      
    flux_period = abs(sin_fit(3));
    sin_fit(4) = mod(sin_fit(4),2*pi);
    
    center_freq(1)=sin_fit(1);
    disp(['average error for the sin flux fit was - ' num2str(mean(err)) 13 10 'maximum error was - ' num2str(max(err)) 13 10 ...
      'SD of error was - ' num2str(std(err))]);
    if display_plots==1
        figure
        plot(flux_values,resonance_freqs,'.')
        hold on;
        q=sin_fit;
        theory_fit=q(1)+q(2).*sin(2*pi*flux_values./q(3)+q(4));
        plot(flux_values,theory_fit)
        hold off
        title(['the fit looks like this one @ input gate: ' 10  num2str(gate_values) 'V']); 
    end
    
    flux_offset= wrapTo2Pi(sin_fit(4))*flux_period/2/pi;
    
    while flux_offset < min(flux_values)
        flux_offset = flux_period + flux_offset;
    end
    while flux_offset > max(flux_values)
        flux_offset = flux_period - flux_offset;
    end

    flux_values_theory = linspace(min(flux_values),max(flux_values),60);
    figure
    plot(flux_values, resonance_freqs-center_freq,'o', 'displayName', 'data freqs')
    hold on
    plot(flux_values_theory, sin_fit(1)+sin_fit(2).*sin(2*pi*flux_values_theory./sin_fit(3)+sin_fit(4))-center_freq, 'displayName', 'Theory freqs');
    plot(flux_offset,0,'x', 'MarkerSize', 16, 'displayName', 'offset point')
    legend show
    
        flux_offset = flux_offset;
        resonance_freqs = resonance_freqs';
        disp(['fit error was ' num2str(err)])
        disp(['the flux period is ' num2str(flux_period) 'V , the center freq is ' num2str(center_freq/1e9) 'GHz and the offset is ' num2str(flux_offset) ' V'])
    %     gate_period=40.683;
        user=input('does this flux period and flux offset seem reasonable?. 1 - proceed, 0 - offset by additional half period, 2 to switch sign of offset');
        if user == 2
            flux_offset = -flux_offset;
            disp(['the flux period is ' num2str(flux_period) 'V , the center freq is ' num2str(center_freq/1e9) 'GHz and the offset is ' num2str(flux_offset) ' V'])
            user=input('does this flux period and flux offset seem reasonable?. 0 - offset by additional half period or 1 - proceed ');
        end
        if user == 1
            [~,closest_flux_value_index] = min(abs(flux_values - flux_offset));
            if resonance_freqs(closest_flux_value_index) - resonance_freqs(closest_flux_value_index + 1) < 0
                offset_slope = 1;
            elseif resonance_freqs(closest_flux_value_index) - resonance_freqs(closest_flux_value_index + 1) > 0
                offset_slope = 0;
            end
            figure
            plot((flux_values - flux_offset + (-1)^offset_slope*flux_period/4)/flux_period,resonance_freqs,'o');
            xlabel('$\frac{\Phi_{\mathrm{ext}}}{\Phi_0}$', 'interpreter', 'latex')
            ylabel(['res freqs for gate ' num2str(gate_values)])
            title('shifted res freqs as a function of flux')
        elseif user == 0
            flux_offset = flux_offset - flux_period/2;
            [~,closest_flux_value_index] = min(abs(flux_values - flux_offset));
            if resonance_freqs(closest_flux_value_index) - resonance_freqs(closest_flux_value_index + 1) < 0
                offset_slope = 1;
            elseif resonance_freqs(closest_flux_value_index) - resonance_freqs(closest_flux_value_index + 1) > 0
                offset_slope = 0;
            end
            figure
            plot((flux_values - flux_offset + (-1)^offset_slope*flux_period/4)/flux_period*2,resonance_freqs,'o');
            xlabel('$\frac{\Phi_{\mathrm{ext}}}{\Phi_0}$', 'interpreter', 'latex')
            ylabel(['res freqs for gate ' num2str(gate_values)])
            title('shifted res freqs as a function of flux')
        end
        user = input('is the sin curve peaked at 0? 1 - proceed, 0 - shift by full period right, 2 - shift by full period left');
        close all;
        if user == 1
            return
        elseif user == 0
            flux_offset = flux_offset - flux_period;
        elseif user == 2
            flux_offset = flux_offset + flux_period;
        end
        figure
        plot((flux_values - flux_offset + (-1)^offset_slope*flux_period/4)/flux_period*2,resonance_freqs,'o', 'displayName', 'Data');
        hold on
        plot((flux_values_theory - flux_offset + (-1)^offset_slope*flux_period/4)/flux_period*2, ...
            center_freq + sin_fit(1)+sin_fit(2).*sin(2*pi*flux_values_theory./sin_fit(3)+sin_fit(4))-center_freq, 'displayName', 'Theory freqs');
        xlabel('$\frac{\Phi_{\mathrm{ext}}}{\Phi_0}$', 'interpreter', 'latex')
        ylabel(['res freqs for gate ' num2str(gate_values) ' (Hz)'])
        title('Final shifted res freqs as a function of flux')
        legend show
        input('hit enter to continue')
        close all;
end
  