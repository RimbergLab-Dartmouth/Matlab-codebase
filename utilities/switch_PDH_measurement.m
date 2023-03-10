function [] = switch_PDH_measurement(keysight_sg, ps_2)
    if exist('ps_2', 'var')
        hp_6612c_set_voltage(ps_2,10,'on');
    end
    n5183b_set_amplitude(keysight_sg, -65)
    two_way_switch_control('A', 1)
    two_way_switch_control('B', 1)
    two_way_switch_control('C', 1)
    two_way_switch_control('D', 1)
	four_way_switch_control(4);
    disp('switched to PDH setup')
end