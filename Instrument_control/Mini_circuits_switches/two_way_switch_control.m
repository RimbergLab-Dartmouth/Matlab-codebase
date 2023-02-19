function [] = two_way_switch_control(switch_number, port_number) % switch_number: 'A', 'B', 'C', 'D' port_number: 0 or 1. 
    MCL_SW=NET.addAssembly('C:\Users\rimberg-lab\Desktop\Git_backed\Instrument_control\Mini_circuits_switches\mcl_RF_Switch_Controller_NET45.dll');
%     MCL_SW=NET.addAssembly('C:\Users\Sisira\Desktop\Matlab-codebase\Instrument_control\Mini_circuits_switches\mcl_RF_Switch_Controller_NET45.dll');
    MyPTE2 = mcl_RF_Switch_Controller_NET45.USB_RF_SwitchBox;
    status = MyPTE2.Connect('02002180110');
    
    status = MyPTE2.Set_Switch(switch_number, port_number);
%     [status, portvalue] = MyPTE1.GetSwitchesStatus('');
%     if status > 0 && portvalue == port_number
%         return
%     else
%         disp('switching failed')
%     end

    MyPTE2.Disconnect();
end




