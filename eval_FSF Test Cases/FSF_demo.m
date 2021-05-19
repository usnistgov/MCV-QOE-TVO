%dat_dir='\\cfs2w.nist.gov\671\Projects\MCV\Volume-test\Volume Impact Project\Pytesting\eval_FSF Test Cases\';
dat_dir='.\';

dat=readtable(fullfile(dat_dir,'FSF-reference-values.csv'));

method=eval_FSF();

for k=1:height(dat)
    [tx_audio,tx_fs]=audioread(fullfile(dat_dir,dat.AudioFile{k}));
    [rx_audio,rx_fs]=audioread(fullfile(dat_dir,sprintf('Rx%i.wav',k)));
   
    %calculate delay
    dly_its=1e-3*sliding_delay_estimates(rx_audio,tx_audio,rx_fs);
    dly_its=mean(dly_its); 
    %interpolate for new time
    rec_int=griddedInterpolant((1:length(rx_audio))/rx_fs-dly_its,rx_audio);

    %new shifted version of signal
    rx_aligned=rec_int((1:length(tx_audio))/tx_fs);
    
    % Save delay corrected recording
    dly_cor_name = sprintf('Rx%i_dly_corrected.wav',k);
    audiowrite(dly_cor_name,rx_aligned,tx_fs);
    
    calc_fsf=method.process({rx_aligned},{tx_audio},1);
    
    if(abs(calc_fsf-dat.FSF(k))>0.0001)
        fprintf(2,'FSF values do not match for row %i. Calculated %f, expected %f\n',k,calc_fsf,dat.FSF(k))
    else
        fprintf('FSF values match for row %i. Calculated %f, expected %f\n',k,calc_fsf,dat.FSF(k))
    end
    
end