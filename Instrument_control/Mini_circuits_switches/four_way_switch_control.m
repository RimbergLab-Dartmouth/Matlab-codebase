function [] = four_way_switch_control(port_number) % 0 (all disconnected), to 4. 
%     MCL_SW=NET.addAssembly('C:\Users\rimberg-lab\Desktop\Git_backed\Instrument_control\Mini_circuits_switches\mcl_RF_Switch_Controller_NET45.dll');
    MCL_SW=NET.addAssembly('C:\Users\Sisira\Desktop\Matlab-codebase\Instrument_control\Mini_circuits_switches\mcl_RF_Switch_Controller_NET45.dll');    
    MyPTE1 = mcl_RF_Switch_Controller_NET45.USB_RF_SwitchBox;
    status = MyPTE1.Connect('02003310056');
    
    status = MyPTE1.Set_SP4T_COM_To(port_number);
%     [status, portvalue] = MyPTE1.GetSwitchesStatus('');
%     if status > 0 && portvalue == port_number
%         return
%     else
%         disp('switching failed')
%     end

    MyPTE1.Disconnect();
end

