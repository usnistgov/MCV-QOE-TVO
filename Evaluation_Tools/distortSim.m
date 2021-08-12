function [opt,vol,y,dat_idx]=distortSim(aMetric,optMethod,noiseFunc,clipFunc,audioFiles,varargin)
%DISTORTSIM simulate volume optimization with noise and clipping.
%   opt=distortSim(aMetric,optMethod,noiseFunc,clipFunc,audioFiles) run a
%   distortion simulation with the audio files given by the cell array
%   audioFiles. Noise is added to the audio file using noiseFunc and the
%   audio is clipped with clipFunc. The optimization method optMethod which
%   is a method_max. The audio is evaluated by a metric which must be a
%   method_eval.
%
%   opt=distortSim(...,name,value) same as above, but with name value
%   parameters passed. Valid name value pairs are shown below.
%
%   noiseFunc is a function that gets called to generate a noise vector to
%   add to the audio. It takes two parameters, len and vol. len is the
%   length of the noise vector. vol is the simulated output volume used for
%   the current trial. noiseFunc should return a vector of noise to be
%   added to the audio.
%
%   clipFunc is a function that gets called to clip the audio data. It
%   takes two parameters, x and vol. x is the audio vector for the trial.
%   vol is the volume level for the trial. clipFun should return a clipped
%   version of x.
%
%   name        Type                description
%   =======================================================================
%
%   tol         numeric scalar      Tolerance for end condition. This is
%                                   passed to optMethod. Default, 1.
%
%   range       numeric             Two element vector of the starting
%                                   range for optMethod. This is passed to
%                                   optMethod. Default [-40,0].
%
%   recycle     logical             When true, don't re-evaluate function
%                                   and re-add noise, just use previously
%                                   computed values. Default, false.
%
%   maxIttr     numeric scalar      Maximum number of iterations to run.
%                                   defaults to 50.
%
%   Trials      numeric scalar      Number of evaluations to do at each
%                                   volume. Default, 1.
%
%See also: method_eval, method_max, noise_func1, clip_mx0p04_s15, clip_mx0p4_s15   
%

%This software was developed by employees of the National Institute of
%Standards and Technology (NIST), an agency of the Federal Government.
%Pursuant to title 17 United States Code Section 105, works of NIST
%employees are not subject to copyright protection in the United States and
%are considered to be in the public domain. Permission to freely use, copy,
%modify, and distribute this software and its documentation without fee is
%hereby granted, provided that this notice and disclaimer of warranty
%appears in all copies.
%
%THE SOFTWARE IS PROVIDED 'AS IS' WITHOUT ANY WARRANTY OF ANY KIND, EITHER
%EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, ANY
%WARRANTY THAT THE SOFTWARE WILL CONFORM TO SPECIFICATIONS, ANY IMPLIED
%WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
%FREEDOM FROM INFRINGEMENT, AND ANY WARRANTY THAT THE DOCUMENTATION WILL
%CONFORM TO THE SOFTWARE, OR ANY WARRANTY THAT THE SOFTWARE WILL BE ERROR
%FREE. IN NO EVENT SHALL NIST BE LIABLE FOR ANY DAMAGES, INCLUDING, BUT NOT
%LIMITED TO, DIRECT, INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES, ARISING
%OUT OF, RESULTING FROM, OR IN ANY WAY CONNECTED WITH THIS SOFTWARE,
%WHETHER OR NOT BASED UPON WARRANTY, CONTRACT, TORT, OR OTHERWISE, WHETHER
%OR NOT INJURY WAS SUSTAINED BY PERSONS OR PROPERTY OR OTHERWISE, AND
%WHETHER OR NOT LOSS WAS SUSTAINED FROM, OR AROSE OUT OF THE RESULTS OF, OR
%USE OF, THE SOFTWARE OR SERVICES PROVIDED HEREUNDER.

   %% ======================[Parse Input Arguments]======================

    %create new input parser
    p=inputParser();

    %add method argument
    addRequired(p,'aMetric',@(m)validateattributes(m,{'method_eval'},{'scalar'}));
    addRequired(p,'optMethod',@(m)validateattributes(m,{'method_max'},{'scalar'}));
    addRequired(p,'noiseFunc',@(f)validateattributes(f,{'function_handle'},{'scalar'}));
    addRequired(p,'clipFunc',@(f)validateattributes(f,{'function_handle'},{'scalar'}));
    addRequired(p,'audioFiles',@validateAudioFiles);
    
    %add recycle parameter
    addParameter(p,'recycle',false,@(l)validateattributes(l,{'logical','numeric'},{'scalar'}));
    %add iteration limit parameter
    addParameter(p,'maxIttr',50,@(l)validateattributes(l,{'numeric'},{'real','finite','scalar','positive'}));
    %add number of trials per volume level parameter
    addParameter(p,'Trials',40,@(t)validateattributes(t,{'numeric'},{'scalar','positive','integer'}));
    %add tolerance parameter
    addParameter(p,'tol',1,@(t)validateattributes(t,{'numeric'},{'scalar','nonnegative','finite'}));
    %range of values to consider
    addParameter(p,'range',[-40,0],@(r)validateattributes(r,{'numeric'},{'vector','numel',2,'increasing'}));

    %parse inputs
    parse(p,aMetric,optMethod,noiseFunc,clipFunc,audioFiles,varargin{:});

    %% ==================[Read in Audio file(s) for test]==================

    %check if audio file is a cell array
    if(iscell(p.Results.audioFiles))
        %yes, copy
        AudioFiles=p.Results.audioFiles;
    else
        %no, create cell array
        AudioFiles={p.Results.audioFiles};
    end

    %cell array of audio clips to use
    aclips=cell(size(AudioFiles));
    %cell array of cut points
    cutpoints=cell(size(AudioFiles));

    %sample audio sample rate to use
    fs=48e3;

    %read in audio files and perform checks
    for k=1:length(AudioFiles)
        %read audio file
        [aclips{k},fs_file]=audioread(AudioFiles{k});

        %check fs and resample if necessary
        if(fs_file~=fs)
            %calculate resample factors
            [prs,qrs]=rat(fs/fs_file);
            %resample to 48e3
            aclips{k}=resample(aclips{k},prs,qrs);
        end

        %reshape y to be a column vector/matrix
        aclips{k}=reshape(aclips{k},sort(size(aclips{k}),'descend'));

        %check if there is more than one channel
        if(size(aclips{k},2)>1)
            %warn user
            warning('audio file has %i channels. discarding all but channel 1',size(aclips,2));
            %get first column
            aclips{k}=aclips{k}(:,1);
        end
        
        %scale so max is +-1
        aclips{k}=aclips{k}./(max(abs(aclips{k})));

        %split file into parts
        [path,name,~]=fileparts(AudioFiles{k});

        %create cutpoints name
        cutname=fullfile(path,[name '.csv']);

        %check if file exists
        if(exist(cutname,'file'))
            %read in cutpoints file
            cutpoints{k}=read_cp(cutname);

        else
            warning('Could not find cutpoint file ''%s''',cutname)
        end
    end    
    
    %generate clip index. wrap around after each clip is used
    clipi=mod(1:p.Results.Trials,length(AudioFiles))+1;
    
    %% ========================[preallocate arrays]========================
    
    vol=NaN(p.Results.maxIttr,1);
    y=NaN(p.Results.maxIttr,p.Results.Trials);
    dat_idx=zeros(p.Results.maxIttr,1);
    rec=cell(p.Results.maxIttr,p.Results.Trials);


    %% =======================[Initialize opt method]======================
    
    method=p.Results.optMethod;
    
    %set tolerence
    if(p.Results.tol>0)
        method.tol=p.Results.tol;
    end
    %set range
    method.range=p.Results.range;
    %initialize method
    vol(1)=method.init();
    
    %% =========================[Simulation Loop]=========================
    for k=1:p.Results.maxIttr
        idx=find(abs(vol(1:(k-1))-vol(k))<0.01*p.Results.tol,1,'first');
        if(isempty(idx) || k==1 || (~p.Results.recycle))
            %print message for each point
            fprintf('Evaluating at x = %f\n',vol(k));
            for kk=1:p.Results.Trials
                ac=aclips{clipi(kk)};
                rec{k,kk}=p.Results.clipFunc(ac,vol(k))+p.Results.noiseFunc(length(ac),vol(k));
            end
            y(k,:)=p.Results.aMetric.process(rec(k,:),aclips,clipi,cutpoints);
            dat_idx(k)=k;
        else
            %print message for each point
            fprintf('Duplicate detected, recycling from x = %f\n',vol(k));
            y(k,:)=y(idx,:);
            dat_idx(k)=idx;
        end
        [vol(k+1),done]=method.get_next(vol(k),y(k,:));
        if(done)
            break;
        end
    end
    
    %remove extra elements from arrays
    vol=vol(1:k);
    y=y(1:k,:);
    dat_idx=dat_idx(1:k);
    
    %% ========================[Get optimal value]========================
    
    opt=method.get_opt();
    
    %% ===========================[Plot Results]===========================
    
    figure;
    
    x_rep=repmat(vol,1,p.Results.Trials);
    plot(x_rep(:),y(:),'o','DisplayName',sprintf('%s eval points',method.name));
    
    hold on
    
    if(p.Results.Trials>1)
        y_mean=mean(y,2);
        
        plot(vol,y_mean,'X','DisplayName','eval mean','MarkerSize',10,'LineWidth',2);
        
        y_std=std(y,0,2);
        
        plot(vol,y_mean+1.96*y_std,'d','DisplayName','uncertainty upper bound','MarkerSize',10,'LineWidth',2);
        plot(vol,y_mean-1.96*y_std,'d','DisplayName','uncertainty lower bound','MarkerSize',10,'LineWidth',2);
        
        
    end
    
    xline(opt,'DisplayName','Max estimate')
    
    legend('Location','NorthEast','Interpreter','none');
    
end


%% =====================[Argument validating functions]=====================
%some arguments require more complex validation than validateattributes can
%provide

function validateAudioFiles(fl)
    validateStr=@(n)validateattributes(n,{'char'},{'vector','nonempty'});
    %check if input is a cell array
    if(iscell(fl))
        %validate each element in the array
        cellfun(validateStr,fl);
    else
        %otherwise validate a single string
        validateStr(fl);
    end
end