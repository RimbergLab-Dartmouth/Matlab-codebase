function [] = switch_phase_measurement_fridge_bypass(ps_2)
    hp_6612c_set_voltage(ps_2,10,'on');
    two_way_switch_control('A', 0)
    two_way_switch_control('B', 1)
    two_way_switch_control('C', 0)
    two_way_switch_control('D', 0)
    four_way_switch_control(3);
end