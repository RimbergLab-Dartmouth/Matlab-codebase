function [] = switch_phase_measurement(ps_2)
    if exist('ps_2', 'var')
        hp_6612c_set_voltage(ps_2,10,'off');
    end
    two_way_switch_control('A', 1)
    two_way_switch_control('B', 0)
    two_way_switch_control('C', 0)
    two_way_switch_control('D', 0)
    four_way_switch_control(3);    
end