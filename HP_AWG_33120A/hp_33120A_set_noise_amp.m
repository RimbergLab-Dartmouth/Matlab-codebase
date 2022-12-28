function[] = hp_33120A_set_noise_amp(awg_address, noise_amp_mVpp)

    fprintf(awg_address, ['APPL:NOIS DEF, ' num2str(noise_amp_mVpp/1e3)])

end