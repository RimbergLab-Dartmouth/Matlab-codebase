clear
instrreset
vna=visa('ni','GPIB0::15::INSTR');
fopen(vna)
set(vna,'Timeout',1000)
fclose(vna)
vna.InputBufferSize = 10000001;
fopen(vna)
dmm_1=visa('ni','GPIB0::5::INSTR');
dmm_2=visa('ni','GPIB0::3::INSTR');
fopen(dmm_1)
fopen(dmm_2)
sa= visa('ni','GPIB0::24::INSTR');
fopen(sa)
set(sa,'Timeout',1000)
fclose(sa)
sa.InputBufferSize = 10000001;
fopen(sa)
keysight_sg=visa('ni','GPIB0::25::INSTR');
fopen(keysight_sg)
hp_sg = visa('ni','GPIB0::22::INSTR');
fopen(hp_sg)
hp_high_freq_sg = visa('ni','GPIB0::13::INSTR');
fopen(hp_high_freq_sg)

hp_33120A_AWG = visa('ni','GPIB0::1::INSTR');
fopen(hp_33120A_AWG)

% ps_2=visa('ni','GPIB0::9::INSTR');
% fopen(ps_2)
ps_2=visa('ni','GPIB0::7::INSTR');
fopen(ps_2)
e8257c_sig_gen=visa('ni','GPIB0::19::INSTR');
fopen(e8257c_sig_gen)
awg=visa('ni','GPIB0::10::INSTR');
fopen(awg)
set(awg,'Timeout',1000)
fclose(awg)
awg.InputBufferSize = 100000001;
fopen(awg)
scope = visa('ni','GPIB0::14::INSTR');
fopen(scope)