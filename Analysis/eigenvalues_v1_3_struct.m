function[freq_shift,dE1,dE1squared,dE1cubed,dE1fourth,E1,E2]=eigenvalues_v1_3_struct(Ej,Ec,charge_states,flux_values_1,gate_values_1,plot_display,center_freq,number_points)
    %%% accepts gate in units of electrons, flux in units of $\Phi_0$
    %%%%%  decides whether to plot eigenenergies or not %%%%%%%%%%%
    if ~exist('plot_display','var')
        plot_display=1;
    end
    %%%%%%%%% generate gate and flux values from experimental values %%%%%%%%
    if ~exist('number_points','var')
        number_points=6;   %number of extra points on each side to calculate derivatives at
    end
    gate_spacing=diff(gate_values_1);
    if ~mean(gate_spacing)==gate_spacing(1)
        return
    end
    flux_values_1 = flux_values_1 *2 * pi;
    gate_spacing=gate_spacing(1);
    flux_spacing=diff(flux_values_1);
    if ~mean(flux_spacing)==flux_spacing(1)
        return
    end
    if ~exist('center_freq','var')
        center_freq = 0;
    end
    %%%%%%%%%%%% always need an odd number of states to make it symmetric
    %%%%%%%%%%%% about 0 %%%%%%%%%%%%%%%
    if mod(charge_states,2)==0
        charge_states=charge_states+1;
    end
    
    delta_0 = 0.176; % zpf value
    
    flux_spacing=flux_spacing(1);
    gate=[];
    flux=[];

    gate=gate_values_1;
    %%% intersperse flux array with additional points for derivatives
    for i=1:length(flux_values_1)
        flux_temp=linspace(flux_values_1(i)-number_points*flux_spacing/20,flux_values_1(i)+number_points*flux_spacing/20,2*number_points+1);
        flux=[flux,flux_temp];
    end

    %%%% generate CPT Hamiltonian as in eqn. (4) of 
    %%%% https://journals.aps.org/prapplied/abstract/10.1103/PhysRevApplied.15.044009
     v=-(charge_states-1)/2:1:(charge_states-1)/2;
     charge=ones(charge_states,charge_states);
     josephson=ones(charge_states,charge_states);
     for i=1:length(gate)
         for j=1:length(flux)
             charge(:,:)=diag(v-gate(i)/2);
             charge(:,:)=4*Ec*charge(:,:).^2;
             
             u=ones(length(diag(josephson(:,:),1)),1);
             u=-Ej*cos(flux(j)/2).*u;
             josephson(:,:)=diag(u,1)+diag(u,-1);
             
             H=charge+josephson;
             
             eigenvalue(:,j,i)=eig(H);
             E1(j,i)=eigenvalue(1,j,i);
             E2(j,i)=eigenvalue(2,j,i);
         end
     end
    %%%%%%%%%%%%%%%%%%%%%%%%%%


     %%%%%%%%%%%%%% plot eigenenergies if needed %%%%%%%%%%%%%%
    if plot_display==1
        figure
        hold on
        q=surf(gate,flux/2/pi,E1);
        xlabel('Number of gate electrons','Interpreter','latex');  
        ylabel('Flux ($\Phi_{ext}/\Phi_0$)','Interpreter','latex');
        zlabel('E');
        set(q,'LineStyle','none');
        w=surf(gate,flux/2/pi,E2);
        view(90,270);
        tit=['first two eigenenergies for Ej=' num2str(Ej/1e9) 'GHz Ec=' num2str(Ec/1e9) 'GHz'];
        title(tit);
        set(w,'LineStyle','none'); 
        hold off
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%% initiate arrays for derivatives %%%%%%%%%%%%
    dE1=ones(size(E1));
    dE1squared=ones(size(E1));
    dE1cubed=ones(size(E1));
    dE1fourth=ones(size(E1));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%% calculate first 4 derivatives & freq shifts %%%%%%%%%%%%%%%%%%%%%%%%
    for i=1:length(gate)
        for j=1:length(flux_values_1)
            dE1_temp=ones(2*number_points+1,1); 
            dE1squared_temp=ones(2*number_points+1,1);
            dE1cubed_temp=ones(2*number_points+1,1);
            dE1fourth_temp=ones(2*number_points+1,1);
            offset_number=number_points+1+(j-1)*(2*number_points+1);
            dE1_temp(:)=numerical_derivative(E1(offset_number-number_points:offset_number+number_points,i),...
                flux(offset_number-number_points:offset_number+number_points),1);
            dE1(offset_number,i)=dE1_temp(number_points+1);
            dE1squared_temp(:)=numerical_derivative(E1(offset_number-number_points:offset_number+number_points,i),...
                flux(offset_number-number_points:offset_number+number_points),2);
            dE1squared(offset_number,i)=dE1squared_temp(number_points+1);
            dE1cubed_temp(:)=numerical_derivative(E1(offset_number-number_points:offset_number+number_points,i),...
                flux(offset_number-number_points:offset_number+number_points),3);
            dE1cubed(offset_number,i)=dE1cubed_temp(number_points+1);
            dE1fourth_temp(:)=numerical_derivative(E1(offset_number-number_points:offset_number+number_points,i)/1e9,...
                flux(offset_number-number_points:offset_number+number_points),4)*1e9;
            dE1fourth(offset_number,i)=dE1fourth_temp(number_points+1);
        end
    end
    dE1=dE1(number_points+1:2*number_points+1:end,:);
    dE1squared=dE1squared(number_points+1:2*number_points+1:end,:);
    dE1cubed=dE1cubed(number_points+1:2*number_points+1:end,:);
    dE1fourth=dE1fourth(number_points+1:2*number_points+1:end,:);
    freq_shift=dE1squared.*delta_0^2;%+1/2*dE1fourth.*delta_0^4;
    shifted_freqs = center_freq + freq_shift;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if plot_display==1
    figure
    r=surf(gate_values_1,flux_values_1/2/pi,dE1);
    set(r,'LineStyle','none');
    view(90,270)
    xlabel('Number of gate electrons','Interpreter','latex');  
    ylabel('Flux ($\Phi_{ext}/\Phi_0$)','Interpreter','latex');  
    zlabel('dE1');
    colorbar
    title('dE1')
    
    figure
    r=surf(gate_values_1,flux_values_1/2/pi,dE1squared.*delta_0^2);
    set(r,'LineStyle','none');
    view(90,270)
    xlabel('Number of gate electrons', 'Interpreter','latex');  
    ylabel('Flux ($\Phi_{ext}/\Phi_0$)','Interpreter','latex');  
    zlabel('linear Freq shift term');
    caxis([-1.5e8 1.5e8])
    colorbar
    title('Linear freq shift in Hz')
    
    figure
    r=surf(gate_values_1,flux_values_1/2/pi,dE1cubed);
    set(r,'LineStyle','none');
    view(90,270)
    xlabel('Number of gate electrons', 'Interpreter','latex');  
    ylabel('Flux ($\Phi_{ext}/\Phi_0$)','Interpreter','latex');
    zlabel('dE1cubed');
    caxis([-1.5e9 1.5e9])
    colorbar
    title('dE1cubed')
    
    figure
    r=surf(gate_values_1,flux_values_1/2/pi,1/2*dE1fourth.*delta_0^4);
    set(r,'LineStyle','none');
    view(90,270)
    xlabel('Number of gate electrons','Interpreter','latex');  
    ylabel('Flux ($\Phi_{ext}/\Phi_0$)','Interpreter','latex');
    zlabel('Kerr term (Hz)');
    caxis([-1e6 1e6])
    colorbar
    title('Kerr term in Hz')
    
    figure
    r=surf(gate_values_1,flux_values_1/2/pi,freq_shift);
    set(r,'LineStyle','none');
    view(90,270)
    xlabel('Number of gate electrons','Interpreter','latex');  
    ylabel('Flux ($\Phi_{ext}/\Phi_0$)','Interpreter','latex');
    zlabel('freq_shift');
    caxis([-1.5e8 1.5e8])
    colorbar
    title(['freq shift for Ej = ' num2str(Ej/1e9) 'GHz, Ec = ' num2str(Ec/1e9) 'GHz'])
    
    figure
    r=surf(gate_values_1,flux_values_1/2/pi,shifted_freqs);
    set(r,'LineStyle','none');
    view(90,270)
    xlabel('Number of gate electrons','Interpreter','latex');  
    ylabel('Flux ($\Phi_{ext}/\Phi_0$)','Interpreter','latex');
    zlabel('freq_shift');
    caxis([-1.5e8 1.5e8])
    colorbar
    title(['freq shift for Ej = ' num2str(Ej/1e9) 'GHz, Ec = ' num2str(Ec/1e9) 'GHz'])
  end
end