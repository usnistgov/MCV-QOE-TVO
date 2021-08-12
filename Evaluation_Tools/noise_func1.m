function [n] = noise_func1(len,vol)
%NOISE_FUNC1 example noise function for distortSim
%   n=NOISE_FUNC1(len,vol) will generate noise of length len for volume
%   vol. The noise is normally distributed with a standard deveation of
%   0.01 for volumes above -33 dB and increases for volumes below -33 dB
%
%See also: distortSim
%

    %point where noise starts to go up
    bp=-33;
    nlev=0.01;
    if(vol<=bp)
        nlev=(-1*(vol-bp))*nlev;
    end
    n=random('Normal',0,nlev,len,1);
end

