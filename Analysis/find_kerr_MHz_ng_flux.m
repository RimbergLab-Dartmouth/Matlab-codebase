function [kerr_required_MHz] = find_kerr_MHz_ng_flux(ng_value, flux_value)
    try 
        load('C:\Users\rimberg-lab\Desktop\Git_backed\Analysis\kerr_data_for_jules_sample.mat', 'kerr_data_struct');
    catch
    end
    try 
       load('D:\Academics\E-Books\Dartmouth\Rimberg_Lab\Matlab-codebase\Analysis\kerr_data_for_jules_sample.mat', 'kerr_data_struct');
    catch
    end
    try 
       load('C:\Users\Sisira\Desktop\Matlab-codebase\Analysis\kerr_data_for_jules_sample.mat', 'kerr_data_struct');
    catch
    end
    

    ng_value = mod(ng_value,1);
    flux_value = mod(flux_value, 1);
    
    [~, ng_number] = min(abs(ng_value - kerr_data_struct.gate_values));
    [~, flux_number] = min(abs(flux_value - kerr_data_struct.flux_values));
    kerr_required_MHz = kerr_data_struct.kerr_MHz(flux_number, ng_number);    
end