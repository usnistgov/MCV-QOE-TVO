function [eval_vals,clipi]=evalTest(fname,func,varargin)
%EVALTEST run an evaluation function on test data
%
%   EVALTEST(vol_adj_file,func) evaluates the method evaluation, func, for
%   each volume in a volume adjust file. The function is called once for
%   each volume setting.
%
%   EVALTEST(m2e_files,func) evaluates func across a series of mouth to ear
%   tests. The function is called once for each test file.
%
%   EVALTEST(m2e_files,{func1,func2}) same as above but evaluates both
%   func1 and func2. In the legend functions are labeled using the return
%   value from func2str if they are functions and class if they are
%   classes.
%
%   EVALTEST(m2e_files,func,'XVals',xvals) same as above but uses xvals as
%   the x-axis values instead of giving an index.
%
%   EVALTEST(m2e_files,func,'XVals',xvals,'Xlabel',xlab) same as above but
%   label the plot x-axis with xlab instead of xvals.
%
%   EVALTEST(__,'ClipPath','path/to/clips') same as above but tells
%   EVALTEST to look for clips in 'path/to/clips'. This is used to locate
%   cutpoints for the audio clips so that they can be passed to the method
%   evaluation function. 
%
%   EVALTEST(__,'CatchEvalErr',false) same as above but stops if the an
%   error is thrown by the evaluation method. Normally a warning is issued
%   when an error is encountered to prevent one small error from screwing
%   up everything. Setting CatchEvalErr to false is useful when debugging
%   an eval method as it stops when there is a problem and may give more
%   useful information vs a warning.
%
%   Method Evaluation Function
%  
%   The method evaluation function is called for each volume level. The
%   function is called with the following arguments: rec, y, clipi,
%   cutpoints. The cell array rec contains the recording data. The cell
%   array y has the playback waveforms. The array clipi has the playback
%   waveform index for each recording. If the cutpoints are known they are
%   passed as a cell array in cutpoints. If the cutpoints could not be
%   loaded (a warning will be given when evalTest loads in the file) then
%   an empty cell array is passed for cutpoints. The method evaluation
%   function returns a numeric scalar for the score.
%   
%   Method Evaluation Class
%
%   Alternatively the method evaluation can be specified by a class. This
%   class must be a subclass of the method_eval class and define the
%   process method. In this case the process method is called each time
%   with the same arguments as a method evaluation function would. This
%   allows for the class to load in datasets used for evaluation (such as
%   ABC_MRT templates) so that they don't have to be loaded in each time.
%   It also allows for parameters of the method to be changed without
%   changing the code.
%
%   See also VOLUME_ADJUST, VOLUME_SORT, METHOD_EVAL, FUNC2STR, CLASS.
%
%
% This software was developed by employees of the National Institute of 
% Standards and Technology (NIST), an agency of the Federal Government and 
% is being made available as a public service. Pursuant to title 17 United 
% States Code Section 105, works of NIST employees are not subject to 
% copyright protection in the United States.  This software may be subject 
% to foreign copyright.  Permission in the United States and in foreign 
% countries, to the extent that NIST may hold copyright, to use, copy, 
% modify, create derivative works, and distribute this software and its 
% documentation without fee is hereby granted on a non-exclusive basis, 
% provided that this notice and disclaimer of warranty appears in all copies. 
%
% THE SOFTWARE IS PROVIDED 'AS IS' WITHOUT ANY WARRANTY OF ANY KIND, EITHER
% EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, ANY 
% WARRANTY THAT THE SOFTWARE WILL CONFORM TO SPECIFICATIONS, ANY IMPLIED 
% WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
% FREEDOM FROM INFRINGEMENT, AND ANY WARRANTY THAT THE DOCUMENTATION WILL 
% CONFORM TO THE SOFTWARE, OR ANY WARRANTY THAT THE SOFTWARE WILL BE ERROR 
% FREE.  IN NO EVENT SHALL NIST BE LIABLE FOR ANY DAMAGES, INCLUDING, BUT 
% NOT LIMITED TO, DIRECT, INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES, 
% ARISING OUT OF, RESULTING FROM, OR IN ANY WAY CONNECTED WITH THIS SOFTWARE, 
% WHETHER OR NOT BASED UPON WARRANTY, CONTRACT, TORT, OR OTHERWISE, WHETHER 
% OR NOT INJURY WAS SUSTAINED BY PERSONS OR PROPERTY OR OTHERWISE, AND 
% WHETHER OR NOT LOSS WAS SUSTAINED FROM, OR AROSE OUT OF THE RESULTS OF, 
% OR USE OF, THE SOFTWARE OR SERVICES PROVIDED HEREUNDER.
%

%create new input parser
p=inputParser();

%add file name parameter
addRequired(p,'fname',@validateFnames);
%add evaluation function parameter
addRequired(p,'EvalFunc',@valideateEval);
%add clip folder
addParameter(p,'ClipPath','',@(n)validateattributes(n,{'char'},{'scalartext'}));
%add x-axis values parameter
addParameter(p,'XVals',[],@(v)validateattributes(v,{'numeric'},{'vector'}));
%add x-axis label parameter
addParameter(p,'XLabel',[],@(l)validateattributes(l,{'char'},{'scalartext'}));
%add catch eval error parameter
addParameter(p,'CatchEvalErr',true,@(l)validateattributes(l,{'logical','numeric'},{'scalar'}));
%add table output parameter
addParameter(p,'TableOut',false,@(l)validateattributes(l,{'logical','numeric'},{'scalar'}));
%add units parameter
addParameter(p,'Xunits',[],@(l)validateattributes(l,{'char'},{'scalartext'}));
%add one at a time parameter
addParameter(p,'OneAtATime',false,@(l)validateattributes(l,{'logical','numeric'},{'scalar'}));
%add single value parameter
addParameter(p,'SingleValue',true,@(l)validateattributes(l,{'logical','numeric'},{'scalar'}));

%parse inputs
parse(p,fname,func,varargin{:});

%check for problems
if(p.Results.OneAtATime && p.Results.TableOut)
    error('''TableOut'' can not be used with ''OneAtATime'' at this time');
end
if(~p.Results.SingleValue && p.Results.TableOut)
    error('''TableOut'' can only be used when ''SingleValue'' is true at this time');
end

if(~iscell(fname))
    dat=load(fname);

    y=dat.y;

    %generate time vector for y
    t_y=cellfun(@(v)(1:length(v))/dat.fs,y,'UniformOutput',false);
    

    %check for cutpoints
    if(isfield(dat,'cutpoints'))
        cutpoints=dat.cutpoints;
    else
        cutpoints=findCP(dat,p.Results.ClipPath);
    end

    ftype=testType(dat);
    
    if(strcmp(ftype,'volume'))
        Trials=size(dat.recordings,2);
    elseif(strcmp(ftype,'volume2.0'))
        Trials=size(dat.test_dat.recordings,2);
    else
        Trials=1;
    end
else
    Trials=length(fname);
end

%check if cell array given for EvalFunc
if(iscell(p.Results.EvalFunc))
    %yes, use it
    eval_methods=p.Results.EvalFunc;
else
    %no, make into cell array
    eval_methods={p.Results.EvalFunc};
end

Methods=length(eval_methods);

errors=cell(Trials,Methods);
if(p.Results.OneAtATime || ~p.Results.SingleValue)
    eval_vals=cell(Trials,Methods);
else
    eval_vals=NaN(Trials,Methods);
end
valid_rec=ones(1,Trials,'logical');
clipi=cell(Trials,1);

for k=1:Trials
    fprintf('Evaluating at volume %u of %u\n',k,Trials);
    %check if we are loading multiple files
    if(iscell(fname))
        %load in new file
        dat=load(fname{k});
        %get type
        ftype=testType(dat);
        %check type
        if(startsWith(ftype,'volume'))
            error('volume test files must be passed one at a time');
        end
        y=dat.y;
        rec=dat.recordings;

        %generate time vector for y
        t_y=cellfun(@(v)(1:length(v))/dat.fs,y,'UniformOutput',false);
        
        %check if y is a cell array
        if(iscell(y))
            %check for clipi in data file
            if(isfield(dat,'clipi'))
                %clipi found, use
                clipi{k}=dat.clipi;
            else
                %no clipi, generate clip index. wrap around after each clip is used
                clipi{k}=mod((1:length(rec))-1,length(y))+1;
            end
        else
            %only one clip so clipi is all the same
            clipi{k}=ones(1,length(rec));
            %make y a cell array
            y={y};
        end
        
        %check for cutpoints
        if(isfield(dat,'cutpoints'))
            cutpoints=dat.cutpoints;
        else
            cutpoints=findCP(dat,p.Results.ClipPath);
        end
    else
        if(strcmp(ftype,'volume2.0'))
            rec=dat.test_dat.recordings(:,k);
        else
            rec=dat.recordings(:,k);
        end
        %clipi is the same for all volume levels
        clipi{k}=dat.clipi;
    end
    
    if(all(cellfun(@isempty,rec)))
        valid_rec(k)=false;
    else
        rec_a=cell(size(rec));
        for kk=1:length(rec)
            if(~isfield(dat,'dly_its'))
                dly_its=1e-3*sliding_delay_wrapper(rec{kk},y{clipi{k}(kk)}',dat.fs);
                dly_its=mean(dly_its); 
            else
                dly_its=mean(dat.dly_its{kk}); 
            end
            %interpolate for new time
            rec_int=griddedInterpolant((1:length(rec{kk}))/dat.fs-dly_its,rec{kk});

            %new shifted version of signal
            rec_a{kk}=rec_int(t_y{clipi{k}(kk)});
        end
        %evaluate each method
        for kk=1:Methods
            if(p.Results.OneAtATime)
                results=zeros(1,length(rec_a));
                errs=cell(1,length(rec_a));
                for kj=1:length(rec_a)
                    if(isempty(cutpoints))
                        cp={};
                    else
                        cp=cutpoints(clipi{k}(kj));
                    end
                    [results(kj),errs{kj}]=run_method(eval_methods{kk},rec_a(kj),y(clipi{k}(kj)),1,cp,p.Results.CatchEvalErr);
                end
                eval_vals{k,kk}=results;
                errors{k,kk}=errs;
            else
                [results,errors{k,kk}]=run_method(eval_methods{kk},rec_a,y,clipi{k},cutpoints,p.Results.CatchEvalErr);
                if(p.Results.SingleValue)
                    eval_vals(k,kk)=mean(results);
                else
                    %force row vector
                    eval_vals{k,kk}=reshape(results,1,[]);
                end
            end
        end
    end
end


if(startsWith(ftype,'volume'))
    %volume test, use volumes from file, skip runs with missing recordings
    eval_vals=eval_vals(valid_rec,:);
    if(strcmp(ftype,'volume2.0'))
        domain=dat.test_dat.volume(valid_rec);
    else
        domain=dat.volume(valid_rec);
    end
    x_lbl='volume [dB]';
    x_units='dB';
else
    %M2E tests use parameter values or make them up
    if(~isempty(p.Results.XVals))
        domain=p.Results.XVals;
        if(isempty(p.Results.XLabel))
            x_lbl='Value';
        else
            x_lbl=p.Results.XLabel;
        end
        x_units=p.Results.Xunits;
    else
        domain=1:Trials;
        x_lbl='test number';
        x_units='';
    end
end

figure;

hold on;


% To handle the scenario volume_adjust out of order data make sure order 
% is correct for plotting
[domain_ordered, order] = sort(domain);

for k=1:Methods
    if(p.Results.OneAtATime || ~p.Results.SingleValue)
        temp_x=cell(1,length(domain));
        temp_y=cell(1,length(domain));
        for kk=1:length(domain)
            temp_x{kk}=domain(kk)*ones(size(eval_vals{kk,k}));
            temp_y{kk}=eval_vals{kk,k};
        end
        x=horzcat(temp_x{:});
        y=horzcat(temp_y{:});
        scatter(x,y,'DisplayName',getMethodName(eval_methods{k}));
    else
        %get data for method
        method_dat=eval_vals(:,k);
        ordered_method_dat = method_dat(order,:);
        plot(domain_ordered,ordered_method_dat,'DisplayName',getMethodName(eval_methods{k}));
    end
end

hold off;

xlabel(x_lbl);
ylabel('Function return value');

%turn off interpreter mostly because of underscores
legend('show','Interpreter','none')

if(p.Results.OneAtATime)
    ne=sum(cellfun(@(v)sum(~cellfun(@isempty,v)),errors));
else
    %calculate number of errors
    ne=sum(~cellfun(@isempty,errors));
end

fprintf('There were %i evaluation errors\n',ne);

if(p.Results.TableOut)
    %get size of output data
    se=size(eval_vals);
    %shape output data into a cell array of columns and fix order
    eval_cell=mat2cell(eval_vals(order,:),se(1),ones(1,se(2)));
    %generate table with columns
    varNames=cellfun(@getMethodName,eval_methods,'UniformOutput',false);
    %generate row names from domain
    rNames=strtrim(cellstr(num2str(reshape(domain_ordered,[],1))));
    %add units to row names
    rNames=strcat(rNames,[' ',x_units]);
    eval_vals=table(eval_cell{:},'VariableNames',varNames,'RowNames',rNames); 
end

end

%% helper functions 
    
function [result,err] =  run_method(method,rec,y,clipi,cutpoints,catchErr)
    %set default return values
    result=NaN;
    err='';
    try
            %check for evaluation class
            if(isa(method,'method_eval'))
                %call the process method
                result=method.process(rec,y,clipi,cutpoints);
            else
                %call evaluation function
                result=method(rec,y,clipi,cutpoints);
            end
    catch e
        %save error
        err=e;
        if(catchErr)
            %give warning for error
            warning(e.identifier,'Method returned error : %s',e.message);
        else
            rethrow(e)
        end
    end
end

function validateFnames(n)
    %check if we have a cell array
    if(iscell(n))
        cellfun(@(n)validateattributes(n,{'char'},{'scalartext'}),n);
    else
        validateattributes(n,{'char'},{'scalartext'});
    end
end

function valideateEval(e)
    scalar_fcn=@(f)validateattributes(f,{'function_handle','method_eval'},{'scalar'});
    if(iscell(e))
        cellfun(scalar_fcn,e);
    else
        scalar_fcn(e)
    end
end
    
function type=testType(dat)
    %check for voluem array
    if(isfield(dat,'volume'))
        type='volume';
    else
        if(isfield(dat,'test_dat') && ~isfield(dat.test_dat,'volume'))
            type='M2E';
        else
            type='volume2.0';
        end
    end
end

function name=getMethodName(method)
    if(isa(method,'function_handle'))
        name=func2str(method);
    else
        name=method.name;
    end
end

function cp=findCP(dat,cpath)
    %check if we have arguments
    if(isfield(dat,'p'))
        %check for AudioFile in arguments
        if(isfield(dat.p.Results,'AudioFile'))
            fnames=dat.p.Results.AudioFile;
        %check for AudioFiles in arguments (maybe only for access time)
        elseif(isfield(dat.p.Results,'AudioFiles'))
            fnames=dat.p.Results.AudioFiles;
        else
            fnames='';
        end
    else
        fnames='';
    end
    
    %preallocate
    cp=cell(size(fnames));
        
    if(isempty(fnames))
        warning('Clip file names not found could not load cutpoints')
        return
    end
    
    if(isfolder(cpath))
        
        %look at all the files
        for k=1:length(fnames)
            [cf,cn,~]=fileparts(fnames{k});
            %split again to get foldername
            [~,csf,~]=fileparts(cf);
            %check if there is a matching subfolder in clip directory
            if(isfolder(fullfile(cpath,csf)))
                cut_name=fullfile(cpath,csf,[cn '.csv']);
                if(exist(cut_name,'file'))
                    cp{k}=read_cp(cut_name);
                else
                    warning('Cutpoint file not found ''%s''',cut_name);
                end
            else
                warining('Could not find cutpoints folder ''%s'' in ''%s''',csf,cpath);
            end
        end
    else
        if(isempty(cpath))
            warning('Cutpoints folder not given, could not load cutpoints');
        else
            warning('Cutpoints folder ''%s'' does not exist, could not load cutpoints',cpath);
        end
    end
end
