function [] = switch_sig_gen_sa_measurement_fridge_bypassed(ps_2, keysight_sg)
    hp_6612c_set_voltage(ps_2,10,'on');
    n5183b_set_amplitude(keysight_sg, -65)
    two_way_switch_control('A', 0)
    two_way_switch_control('B', 1)
    two_way_switch_control('C', 1)
    two_way_switch_control('D', 1)
	four_way_switch_control(2);
end