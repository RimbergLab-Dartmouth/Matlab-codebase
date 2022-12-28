function [] = switch_phase_measurement_no_awg(ps_2, keysight_sg)
    hp_6612c_set_voltage(ps_2,10,'off');
	n5183b_set_amplitude(keysight_sg, -65)
    two_way_switch_control('A', 1)
    two_way_switch_control('B', 0)
    two_way_switch_control('C', 1)
    two_way_switch_control('D', 1)
	four_way_switch_control(3);
end