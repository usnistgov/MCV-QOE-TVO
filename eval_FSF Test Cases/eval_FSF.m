classdef eval_FSF < method_eval
%EVAL_FSF - frequency slope fit distortion detector 
%
%   m = EVAL_FSF() creates a frequency slope fit detector using Uniform bands
%
%   The EVAL_FSF class is a method_eval class that uses a linear fit of the
%   power in certain frequency bands to measure distortion.
%
%EVAL_FSF Methods:
%   process    - process recordings to get a distortion estimation
%   filterPlot - plot filter band edges
%   slopeCalc  - calculate slope of a given recording
%
%EVAL_FSF Properties:
%   name      -  method name. 
%   Freq_Set  -  Frequency bands to use
%   FFT_len   -  Length of FFT for band power measurements
%   bandX     -  Use band numbers for x values in fit
%
%   See also EVALTEST, METHOD_EVAL.
%
    properties
%FREQ_SET - The set of frequency band edges as a two column matrix. The
%           first column represents the lower band edges and the second
%           column represents the upper band edges.
        Freq_Set(:,2)=[200 450; 400 650; 600 850; 800 1050; 1000 1250;
                       1200 1450; 1400 1650; 1600 1850; 1800 2050;
                       2000 2250; 2200 2450; 2400 2650; 2600 2850;
                       2800 3050; 3000 3250;];
%FFT_LEN - the FFT length to use for the band power calculations               
       FFT_len=2^14;
%BANDX - logical value that determines if the linear fit x values come from
%        band centers (false) or if band numbers are used (true)
        bandX(1,1) {mustBeNumericOrLogical}=true;
    end
    methods
        function score=process(obj,rec,y,clipi,~)
%PROCESS - calculate a harmonic distortion score from a set of recordings
%
%   score=PROCESS(rec,y,clipi) - return a harmonic distortion score for a
%                                given set of recordings (rec), original
%                                clips (y), and clip indicies (clipi).

            y_slope=zeros(sort(size(y)));
            y_int=zeros(sort(size(y)));
            
            for k=1:length(y)
                [y_slope(k),y_int(k)]=obj.slopeCalc(y{k});
            end

            %preallocate! for speed
            slope=zeros(sort(size(clipi)));
            intercept=zeros(sort(size(clipi)));
            for k=1:length(rec)
                [slope(k),intercept(k)]=obj.slopeCalc(rec{k});
            end
            %compute score for each trial
            score=slope./y_slope(clipi);

        end
        function [slope,intercept]=slopeCalc(obj,dat)
%SLOPECALC - calculate the frequency slope fit for a given recording
%
%   this is an internal method that does a linear fit of the power in a
%   given band and returns the slope, intercept and linear model

            %number of bands
            nbands=size(obj.Freq_Set,1);
            
            %force column vector for dat
            dat=reshape(dat,[],1);

            %calculate periodogram
            [pxx,freq]=periodogram(dat,hamming(length(dat)),obj.FFT_len,48e3,'power');

            %preallocate
            band_val=zeros(nbands,1);

            %calculate data for frequency bands
            for band=1:nbands
                band_val(band)=10*log10(mean(pxx( (freq>=obj.Freq_Set(band,1)) & (freq<=obj.Freq_Set(band,2)) )));
            end

            %get the index of maximum value
            %only consider the first half of the FI bands
            [~,max_i]=max(band_val(1:round(nbands/2)));

            %range of fit is to the right of max
            rng=max_i:length(band_val);

            if(obj.bandX)
                %x-axis values from band number
                xvals=(1:size(obj.Freq_Set,1))';
                %eliminate unused bands
                xvals=xvals(rng);
            else
                %center of each band
                bcenter=mean(obj.Freq_Set,2); 
                %x-axis values from log10 of band centers
                xvals=10*log10(bcenter(rng));
            end
            
            %get linear fit of data
            p=polyfit(xvals,band_val(rng),1);

            %find slope for data
            slope=p(1);
            intercept=p(2);
        end
        
        function filterPlot(obj)
%FILTERPLOT - plot the filter band edges
%
%   FILTERPLOT() makes a plot of the filter bands. The filter bands are
%                represented by rectangles with a x-axis span given by the
%                band edges and the y-axis location corresponding to the
%                band number.

            %number of bands
            nbands=size(obj.Freq_Set,1);
            
            figure;
            hold on;
            filt_colors=lines(nbands);
            %calculate data for frequency bands
            for band=1:nbands
                %create a bar for each filter
                fill(obj.Freq_Set(band,[1 1 2 2]),[1,1,1,1]*band+[-0.4,0.4,0.4,-0.4],filt_colors(band,:),'EdgeColor','none','DisplayName',sprintf('Band #%u',band))
            end
            hold off;
            
            xlabel('Frequency [Hz]');
            ylabel('Filter #');
            
        end
        
    end
    
end