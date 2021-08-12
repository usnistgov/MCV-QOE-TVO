function y=clip_mx0p4_s15(x,vol)
%CLIP_MX0P4_S15 example clipping function for distortSim
%   y=CLIP_MX0P4_S15(x,vol) clips audio vector, x, based on volume vol.
%   Clipping starts for volumes above -15 dB and the level that audio is
%   clipped to decreases from there so that the clipping level at 0 dB is
%   0.4
%
%See also: distortSim
%


    %point with no clipping possible
    bp=-15;
    
    %clip level at zero volume
    zlvl=0.4;
    
    %calculate slope
    m=(1-zlvl)/(bp);
    
    %calculate threshold for 
    thresh=m*vol+zlvl;
    
    %clip waveform
    y=sign(x).*min(abs(x),thresh);
end