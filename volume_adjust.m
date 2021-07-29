function [opt,test_dat]=volume_adjust(varargin)
%VOLUME_ADJUST determine optimal volume for a test setup. A Transmit volume
%Optimization (TVO) tool. 
%
%	[opt,volume]=VOLUME_ADJUST() will play and record audio in the system
%                                to get the optimal volume
%
%	VOLUME_ADJUST(name,value) same as above but specify test parameters as
%	name value pairs. Possible name value pairs are shown below.
%
%   NAME                TYPE                DESCRIPTION
%
%   AudioFile           char vector         Audio file to use for test. If
%                                           a cell array is given then the
%                                           test is run in succession for
%                                           each file in the array.
%
%   Trials              positive int        Number of trials to run for
%                                           each sample volume.
%
%   SMax				positive integer	Maximum number of sample
%                                           volumes to use. Default 30.
%
%   RadioPort           char vector,string  Port to use for radio
%                                           interface. Defaults to the
%                                           first port where a radio
%                                           interface is detected.
%
%   Volumes             double vector       Instead of using the algorithm 
%                                           to determine what volumes to 
%                                           sample,explicitly set the 
%                                           volume sample points. When this
%                                           is given no optimal volume is
%                                           calculated. Default is an empty
%                                           vector.
%
%   DevVolume           double              Volume setting on the device.
%                                           This tells VOLUME_ADJUST what
%                                           the output volume of the audio
%                                           device is. This is taken into
%                                           account when the scaling is
%                                           done for the trials. Default is
%                                           0 dB.
%
%   Scaling				logical	 			Scale the clip volume to
%                                           simulate adjusting the device
%                                           volume to the desired level. If
%                                           this is false then the user
%                                           will be prompted every time the
%                                           volume needs to be changed.
%                                           Defaults to true.
%
%   Lim					double vector		TLim must be a 2 element
%                                           numeric vector that is
%                                           increasing. Lim sets the volume
%                                           limits to use for the test in
%                                           dB. Lim defaults to [-40,0].
%
%	OutDir				char vector			Directory that is added to the
%                                           output path for all files.
%
%	PTTGap				double				Time to pause after completing
%                                           one trial and starting the
%                                           next. Defaults to 3.1 s.
%
%   EvalFunc            method_eval         A function handle or 
%                                           method_eval class to use to 
%                                           compare trials.  
%
%   OptMethod           method_max          A method_max class to use to
%                                           determine which points to
%                                           evaluate next and, at the end,
%                                           return an value.
%
%   tol                 double              Tolerance value. Used to set
%                                           Opt.tol.


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

%% ========================[Parse Input Arguments]========================

%create new input parser
p=inputParser();
%set the default audio clips
default_clips=fullfile('clips',{...
                                'F1_Loud_Norm_DiffNeigh_VaryFill.wav',...
                                'F3_Loud_Norm_DiffNeigh_VaryFill.wav',...
                                'M3_Loud_Norm_DiffNeigh_VaryFill.wav',...
                                'M4_Loud_Norm_DiffNeigh_VaryFill.wav',...
                               });

%add optional filename parameter
addParameter(p,'AudioFile',default_clips,@validateAudioFiles);
%add number of trials per volume level parameter
addParameter(p,'Trials',40,@(t)validateattributes(t,{'numeric'},{'scalar','positive','integer'}));
%add number of trials per volume level parameter
addParameter(p,'PauseTrials',Inf,@(t)validateattributes(t,{'numeric'},{'scalar','positive','integer'}));
%add sample limit parameter
addParameter(p,'SMax',30,@(t)validateattributes(t,{'numeric'},{'scalar','positive'}));
%add radio port parameter
addParameter(p,'RadioPort',[],@(n)validateattributes(n,{'char','string'},{'scalartext'}));
%add volumes parameter
addParameter(p,'Volumes',[],@(n)validateattributes(n,{'numeric'},{'vector'}));
%add device volume parameter
addParameter(p,'DevVolume',0,@(n)validateattributes(n,{'numeric'},{'scalar'}));
%add Scaling enable parameter
addParameter(p,'Scaling',true,@(t)validateattributes(t,{'numeric','logical'},{'scalar'}));
%add Limits parameter
addParameter(p,'Lim',[-40,0],@(t)validateattributes(t,{'numeric','logical'},{'vector','size',[1,2],'increasing'}));
%add output directory parameter
addParameter(p,'OutDir','',@(n)validateattributes(n,{'char'},{'scalartext'}));
%add ptt gap parameter
addParameter(p,'PTTGap',3.1,@(l)validateattributes(l,{'numeric'},{'real','finite','scalar','nonnegative'}));
%add ptt wait parameter
addParameter(p,'PTTWait',0.68,@(t)validateattributes(t,{'numeric'},{'scalar','positive'}));
%add evaluation function parameter
addParameter(p,'EvalFunc',eval_FSF(),@(f)validateattributes(f,{'function_handle','method_eval'},{'scalar'}));
%add optimization method parameter
addParameter(p,'OptMethod',max_OptGrid(),@(m)validateattributes(m,{'method_max'},{'scalar'}));
%add overplay parameter
addParameter(p,'OverPlay',1,@(l)validateattributes(l,{'numeric'},{'real','finite','scalar','nonnegative'}));
%add tolerance parameter
addParameter(p,'tol',1,@(t)validateattributes(t,{'numeric'},{'scalar','nonnegative','finite'}));

%parse inputs
parse(p,varargin{:});

%% ======================[List Vars to save in file]======================
%This is a list of all the files to save in data files. This is done both
%for a normal test run and if an error is encountered. This list is here so
%there is only one place to add new variables that need to be saved in the
%file

save_vars={'p','git_status','y','dev_name','test_dat',...
            'fs','opt','vol_scl_en','clipi','cutpoints','method',...
        ...%save pre test notes, post test notes will be appended later
           'pre_notes'};


%% ===================[Read in Audio file(s) for test]===================

%check if audio file is a cell array
if(iscell(p.Results.AudioFile))
    %yes, copy
    AudioFiles=p.Results.AudioFile;
else
    %no, create cell array
    AudioFiles={p.Results.AudioFile};
end

%cell array of audio clips to use
y=cell(size(AudioFiles));
%cell array of cut points
cutpoints=cell(size(AudioFiles));

%sample audio sample rate to use
fs=48e3;

%read in audio files and perform checks
for k=1:length(AudioFiles)
    %read audio file
    [y{k},fs_file]=audioread(AudioFiles{k});
    
    %check fs and resample if necessary
    if(fs_file~=fs)
        %calculate resample factors
        [prs,qrs]=rat(fs/fs_file);
        %resample to 48e3
        y{k}=resample(y{k},prs,qrs);
    end
    
    %reshape y to be a column vector/matrix
    y{k}=reshape(y{k},sort(size(y{k}),'descend'));
    
    %check if there is more than one channel
    if(size(y{k},2)>1)
        %warn user
        warning('Audio file has %i channels. Discarding all but channel 1',size(y,2));
        %get first column
        y{k}=y{k}(:,1);
    end
    
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

%generate time vector for y
t_y=cellfun(@(v)(1:length(v))/fs,y,'UniformOutput',false);

%% ========================[Setup Playback Object]========================

%create an object for playback and recording
aPR=audioPlayerRecorder(fs);

%save scaling status
vol_scl_en=p.Results.Scaling;

%set bit depth
aPR.BitDepth='24-bit integer';

%chose which device to use
dev_name=choose_device(aPR);

%print the device used
fprintf('Using "%s" for audio test\n',dev_name);

%% ===========================[Read git status]===========================

%get git status
git_status=gitStatus();

%% ==================[Initialize file and folder names]==================

%folder name for data
dat_fold=fullfile(p.Results.OutDir,'data_matfiles');

%folder name for data
error_fold=fullfile(p.Results.OutDir,'data','error');

%folder name for plots
plots_fold=fullfile(p.Results.OutDir,'plots');

%file name for log file
log_name=fullfile(p.Results.OutDir,'tests.log');

%file name for test type
test_name=fullfile(p.Results.OutDir,'test-type.txt');

%make plots directory
[~,~,~]=mkdir(plots_fold);

%make data directory
[~,~,~]=mkdir(dat_fold);

%make error file directory
[~,~,~]=mkdir(error_fold);

%% =========================[Get Test Start Time]=========================

%get start time
dt_start=datetime('now','Format','dd-MMM-yyyy_HH-mm-ss');
%get a string to represent the current date in the filename
dtn=char(dt_start);

%% ==================[Get Test info and notes from user]==================

%open test type file
init_tstinfo=readTestState(test_name);

%width for a device prompt
dev_w=20;
%initialize prompt array
prompt={};
%initialize text box dimensions array
dims=[];
%initialize empty response array
resp={};

%add test type prompt to dialog
prompt{end+1}='Test Type';
dims(end+1,:)=[1,50];
resp{end+1}=init_tstinfo.testType;
%add Tx radio ID prompt to dialog
prompt{end+1}='Transmit Device';
dims(end+1,:)=[1,dev_w];
resp{end+1}=init_tstinfo.TxDevice;
%add Rx radio ID prompt to dialog
prompt{end+1}='Receive Device';
dims(end+1,:)=[1,dev_w];
resp{end+1}=init_tstinfo.RxDevice;
%add radio system under test prompt
prompt{end+1}='System';
dims(end+1,:)=[1,60];
resp{end+1}=init_tstinfo.System;
%add test notes prompt
prompt{end+1}='Please enter notes on test conditions';
dims(end+1,:)=[15,100];

%use empty test notes
resp{end+1}='';

%dummy struct for sys_info
test_info=struct('testType','');

%loop while we have an empty test type
while(isempty(test_info.testType))
    %prompt the user for test info
    resp=inputdlg(prompt,'Test Info',dims,resp);
    %check if anything was returned
    if(isempty(resp))
        %exit program
        return;
    else
        %get test state from dialog
        test_info=getTestState(prompt(1:(end-1)),resp(1:(end-1)));
        %write test state
        writeTestState(test_name,test_info);
    end
    %check if a test type was given
    if(~isempty(test_info.testType))
        %print out test type
        fprintf('Test type : %s\n',test_info.testType);
        %preappend underscore and trim whitespace
        test_type_str=['_',strtrim(test_info.testType)];
        %test_type_str set, loop will now exit
    end
end

%% ===============[Print Log entry so it is easily copyable]===============

%get notes from response
pre_note_array=resp{end};

%get strings from output add newlines only
pre_note_strings=cellfun(@(s)[s,newline],cellstr(pre_note_array),'UniformOutput',false);
%get a single string from response
pre_notes=horzcat(pre_note_strings{:});

%print
fprintf('Pre test notes:\n%s\n',pre_notes);

%% ===============[Parse User response and write log entry]===============

%get strings from output add a tabs and newlines
pre_note_tab_strings=cellfun(@(s)[char(9),s,newline],cellstr(pre_note_array),'UniformOutput',false);
%get a single string from response
pre_notesT=horzcat(pre_note_tab_strings{:});

if(iscell(git_status))
    gstat=git_status{1};
else
    gstat=git_status;
end

%check dirty status
if(gstat.Dirty)
    %local edits, flag as dirty
    gitdty=' dty';
else
    %no edits, don't flag
    gitdty='';
end

%get call stack info to extract current filename
[ST, I] = dbstack('-completenames');
%get current filename parts
[~,n,e]=fileparts(ST(I).file);
%full name of current file without path
fullname=[n e];

%open log file
logf=fopen(log_name,'a+');
%set time format of start time
dt_start.Format='dd-MMM-yyyy HH:mm:ss';
%write start time, test type and git hash
fprintf(logf,['\n>>Test started at %s\n'...
    '\tTest Type  : %s\n'...
    '\tGit Hash   : %s%s\n'...
    '\tfilename   : %s\n'],char(dt_start),test_info.testType,gstat.Hash,gitdty,fullname);
%write Tx device ID
fprintf(logf, '\tTx Device  : %s\n',test_info.TxDevice);
%write Rx device ID
fprintf(logf, '\tRx Device  : %s\n',test_info.RxDevice);
%write system under test
fprintf(logf, '\tSystem     : %s\n',test_info.System);
%write system under test
fprintf(logf, '\tArguments     : %s\n',extractArgs(p,ST(I).file));
%write pre test notes
fprintf(logf,'===Pre-Test Notes===\n%s',pre_notesT);
%close log file
fclose(logf);

%% =======================[Filenames for data files]=======================

%generate base file name to use for all files
base_filename=sprintf('capture%s_%s',test_type_str,dtn);

%generate filename for good data
data_filename=fullfile(dat_fold,sprintf('%s.mat',base_filename));

%generate filename for error data
error_filename=fullfile(error_fold,sprintf('%s_ERROR.mat',base_filename));

%% =======================[Get max number of loops]=======================

if(isempty(p.Results.Volumes))
    %using algorithm, use SMax
    SMax=p.Results.SMax;
else
    %volumes given, use array length
    SMax=length(p.Results.Volumes);
end


%% ======================[Generate oncleanup object]======================

%add cleanup function
co=onCleanup(@()cleanFun(error_filename,data_filename,log_name));

%% ========================[Open Radio Interface]========================

%open radio interface
ri=radioInterface(p.Results.RadioPort);

%% ========================[Notify user of start]========================

%print name and location of file
fprintf('Storing data in:\n\t''%s''\n',data_filename);

%only print assumed device volume if scaling is enabled
if(vol_scl_en)
    %print assumed device volume for confirmation
    fprintf('Assuming device volume of %.2f dB\n',p.Results.DevVolume);
end

%turn on LED when test starts
ri.led(1,true);

try
    
    %% ========================[Preallocate arrays]========================
    %give arrays dummy values so things go faster and mlint doesn't
    %complain
        
    test_dat=struct();
    
    %preallocate arrays
    test_dat.underRun=zeros(p.Results.Trials,SMax);
    test_dat.overRun=zeros(p.Results.Trials,SMax);
    test_dat.recordings=cell(p.Results.Trials,SMax);
    test_dat.volume=zeros(1,SMax);
    test_dat.eval_vals=zeros(1,SMax);
    test_dat.eval_dat=cell(1,SMax);
    
    clipi = reshape(mod(1:p.Results.Trials,length(AudioFiles)) + 1,1,[]);
    
    %set dummy value for opt so that error files get saved
    opt=NaN;                                                                %ok for file saving
    
    trialCount=0;
    
    %% ==================[Setup for optimization method]==================
    %use the desired optimal volume plateau identification algorithm (OVPIA)
    %method to select transmit volume settings to evaluate and find the 
    %optimal value.
    
    method=p.Results.OptMethod;
    method.range=p.Results.Lim;
    method.tol=p.Results.tol;
    
    if(~isempty(p.Results.Volumes))
        test_dat.volume=p.Results.Volumes;
    else
        %save data from optimization method
        test_dat.max_dat=cell(1,SMax);
    end
    
    %% ========================[Volume Selection Loop]=====================
    
    for k=1:SMax
        
        %% ===================[Compute next sample Point]==================
        
        %check if volumes were given
        if(isempty(p.Results.Volumes))
            if(k==1)
                %first run, init
                test_dat.volume(k)=method.init();
                %can't be done before we start
                done=0;
            else
                %process data and get next point
                [test_dat.volume(k),done]=method.get_next(test_dat.volume(k-1),test_dat.eval_dat{k-1});
            end
        
            test_dat.max_dat{k}=copy(method);
            
            %check for convergence
            if(done)
                for v=fieldnames(test_dat)'
                    %only resize nonempty fields
                    if(~isempty(test_dat.(v{1})))
                        test_dat.(v{1})=test_dat.(v{1})(:,1:(k-1));
                    end
                end
                break;
            end

        end  
        
        %% =========================[Skip Repeats]=========================
        
        %check if volumes were given
        if(isempty(p.Results.Volumes))
            %check to see if we are evaluating a value that has been done before
            idx=find(abs(test_dat.volume(k)-test_dat.volume(1:(k-1)))<(p.Results.tol/1e3),1);

            %check if value was found
            if(~isempty(idx))
                fprintf('Repeating volume of %f, using volume from run %i (vol = %f) skipping to next iteration...\n',test_dat.volume(k),idx,test_dat.volume(idx))
                %copy old values
                test_dat.eval_vals(k)=test_dat.eval_vals(idx);
                test_dat.eval_dat(k)=test_dat.eval_dat(idx);
                %skip to next iteration
                continue;
            end
        end
        
        %% ========================[Change Volume]========================
        %volume is changed by scaling the waveform or prompting the user to
        %change it in the audio device configuration
      
        
        %check if we are scaling or using device volume
        if(vol_scl_en)
            %print message with volume level
            fprintf('scaling volume to %f dB\n',test_dat.volume(k));
            
            %scale audio to volume level
            y_scl = cell(length(y),1);
            for jj = 1:length(y_scl)
                y_scl{jj}=(10^((test_dat.volume(k)-p.Results.DevVolume)/20))*y{jj};
            end
            
        else
            %beep to get the users attention
            beep;
            
            %turn on other LED because we are waiting
            ri.led(2,true);
            
            %get volume to set device to
            dvolume=round(test_dat.volume(k));
            
            %prompt user to set new volume
            nv=input(sprintf('Set audio device volume to %f dB and press enter\nEnter actual volume if %f dB was not used\n',dvolume,dvolume));
            
            %check if value was given
            if(~isempty(nv))
                %set actual volume
                dvolume=nv;
            end
            
            %scale audio volume to make up the difference
            %scale audio to volume level
            y_scl = cell(length(y),1);
            for jj = 1:length(y_scl)
                y_scl{jj}=(10^((volume(k)-dvolume)/20))*y{jj};
            end
            
            
            %turn off other LED
            ri.led(2,false);
            
        end
        
        %% =======================[Measurement Loop]=======================
        
        for kk=1:p.Results.Trials
                   
            %%  ================[Key Radio and Play Audio]================
            
            %push the push to talk button
            ri.ptt(true);
            
            %pause to let the radio key up
            pause(p.Results.PTTWait);
            
            %play and record audio data
            [dat,test_dat.underRun(kk,k),test_dat.overRun(kk,k)]=play_record(aPR,y_scl{clipi(kk)},'OverPlay',p.Results.OverPlay);
            
            %check for buffer over runs
            if(test_dat.overRun(kk,k)~=0)
                fprintf('There were %i buffer over runs\n',test_dat.overRun(kk,k));
            end
            
            %check for buffer over runs
            if(test_dat.underRun(kk,k)~=0)
                fprintf('There were %i buffer under runs\n',test_dat.underRun(kk,k));
            end
            
            %un-push the push to talk button
            ri.ptt(false);
            
            %pause between runs
            pause(p.Results.PTTGap);
            
            %increment trial count
            trialCount=trialCount+1;
            
            %%  ================[Check if pause is needed]================
            
            if(mod(trialCount,p.Results.PauseTrials)==0)
                %print message
                fprintf('Trial Limit reached. Check Batteries and press enter to continue\n');
                %beep to alert the user
                beep;
                %pause to wait for user
                pause;
            end
            
            %%  ==================[Clip Data Processing]==================
            
            %save recording
            test_dat.recordings{kk,k}=dat;
            
        %% ===================[End of Measurement Loop]===================
        
        end
        
        %%  ================[Volume Level Data Processing]================
    
        %align audio
        rec_a=cell(1,length(test_dat.recordings(:,k)));
        for kk=1:length(test_dat.recordings(:,k))
            dly_its=1e-3*sliding_delay_wrapper(dat,y{clipi(kk)}',fs);
            dly_avg=mean(dly_its); 
            %interpolate for new time
            rec_int=griddedInterpolant((1:length(test_dat.recordings{kk,k}))/fs-dly_avg,test_dat.recordings{kk,k});

            %new shifted version of signal
            rec_a{kk}=rec_int(t_y{clipi(kk)});
        end
        %check for evaluation class
        if(isa(p.Results.EvalFunc,'method_eval'))
            %call the process method
            test_dat.eval_dat{k}=p.Results.EvalFunc.process(rec_a,y,clipi,cutpoints);
        else
            %call evaluation function
            test_dat.eval_dat{k}=p.Results.EvalFunc(rec_a,y,clipi,cutpoints);
        end
        %compute mean
        test_dat.eval_vals(k)=mean(test_dat.eval_dat{k});
        %print message
        fprintf('Eval method returned %g\n',test_dat.eval_vals(k));
        
    %% =========================[Measurement Loop]=========================
    
    end
    
    if(isempty(p.Results.Volumes))
        %calculate optimal volume
        opt=method.get_opt();
    else
        opt=NaN;
    end
    
    %%  ========================[save datafile]=========================
    
    %save datafile
    save(data_filename,save_vars{:},'-v7.3');   
    
    %%  ===========================[Catch Errors]===========================

catch err
    
    %add error to dialog prompt
    dlgp=sprintf(['Error Encountered with test:\n'...
        '"%s"\n'...
        'Please enter notes on test conditions'],...
        strtrim(err.message));
    
    %get error test notes
    resp=inputdlg(dlgp,'Test Error Conditions',[15,100]);
    
    %open log file
    logf=fopen(log_name,'a+');
    
    %check if dialog was not canceled
    if(~isempty(resp))
        %get notes from response
        post_note_array=resp{1};
        %get strings from output add a tabs and newlines
        post_note_strings=cellfun(@(s)[char(9),s,newline],cellstr(post_note_array),'UniformOutput',false);
        %get a single string from response
        post_notes=horzcat(post_note_strings{:});
        
        %write start time to file with notes
        fprintf(logf,'===Test-Error Notes===\n%s',post_notes);
    else
        %dummy var so we can save
        post_notes='';
    end
    %print end of test marker
    fprintf(logf,'===End Test===\n\n');
    %close log file
    fclose(logf);
    
    %set file status to error
    file_status='error';
    
    %start at true
    all_exist=true;
    
    %look at all vars to see if they exist
    for kj=1:length(save_vars)
        if(~exist(save_vars{kj},'var'))
            %all vars don't exist
            all_exist=false;
            %exit loop
            break;
        end
    end
    
    %check that all vars exist
    if(all_exist)
        %save all data and post notes
        save(error_filename,save_vars{:},'err','post_notes','-v7.3');
        %print out file location
        fprintf('Data saved in ''%s''\n',error_filename);
    else
        %save error post notes and file status
        save(error_filename,'err','post_notes','file_status','-v7.3');
        %print out file location
        fprintf('Dummy data saved in ''%s''\n',error_filename);
    end
    
    %rethrow error
    rethrow(err);
end

%% ===========================[Close Hardware]===========================

%turn off LED when test stops
ri.led(1,false);

%close radio interface
delete(ri);

%% ======================[Check for buffer issues]======================

%check for buffer over runs
if(any(test_dat.overRun))
    fprintf('There were %i buffer over runs\n',sum(sum(test_dat.overRun)));
else
    fprintf('There were no buffer over runs\n');
end

%check for buffer over runs
if(any(test_dat.underRun))
    fprintf('There were %i buffer under runs\n',sum(sum(test_dat.underRun)));
else
    fprintf('There were no buffer under runs\n');
end

%% ===========================[Generate Plots]===========================

%create figure for plot
figure;

%sort volumes
[sv,idx]=unique(test_dat.volume);

sr=test_dat.eval_vals(idx);

%plot function values
plot(sv,sr,'DisplayName',getMethodName(p.Results.EvalFunc));

ylabel('Function Value');
xlabel('Audio Volume [dB]');

%add text for volume points
text(sv,sr,cellstr(num2str(idx))','color','red');

legend('Location','best','Interpreter','none');

%% ==========================[Helper Functions]==========================

function name=getMethodName(method)
if(isa(method,'function_handle'))
    name=func2str(method);
else
    name=method.name;
end

%% ==========================[Cleanup Function]==========================
%This is called when cleanup object co is deleted (Function exits for any
%reason other than CTRL-C). This ensures that the log entries are properly
%closed and that there is a chance to add notes on what went wrong.

function cleanFun(err_name,good_name,log_name)
%check if error .m file exists
if(~exist(err_name,'file'))

    prompt='Please enter notes on test conditions';
    
    %check to see if data file is missing
    if(~exist(good_name,'file'))
        %add not to say that this was an error
        prompt=[prompt,newline,'Data file missing, something went wrong'];
        %no results, no default text
        def_txt='';
    else
        %load in result
        dat=load(good_name,'opt');
        %check if optimal volume was found
        if(~isnan(dat.opt))
            %get opt from result
            def_txt=sprintf('Optimal volume = %f dB\r',dat.opt);
        else
            %no optimal volume, no default text
            def_txt='';
        end
    end
    
    %get post test notes
    resp=inputdlg(prompt,'Test Conditions',[15,100],{def_txt});

    %open log file
    logf=fopen(log_name,'a+');

    %check if dialog was canceled
    if(~isempty(resp))
        %get notes from response
        post_note_array=resp{1};
        %get strings from output add a tabs and newlines
        post_note_strings=cellfun(@(s)[char(9),s,newline],cellstr(post_note_array),'UniformOutput',false);
        %get a single string from response
        post_notes=horzcat(post_note_strings{:});

        %write start time to file with notes
        fprintf(logf,'===Post-Test Notes===\n%s',post_notes);
    else
        %set post notes to default
        post_notes=def_txt;  
        %check if we have anything in post_notes
        if(~isempty(post_notes))
            %write post notes to file
            fprintf(logf,'===Post-Test Notes===\n\t%s',post_notes);
        end
    end
    %print end of test marker
    fprintf(logf,'===End Test===\n\n');
    %close log file
    fclose(logf);

    %check to see if data file exists
    if(exist(good_name,'file'))
        %append post notes to .mat file
        save(good_name,'post_notes','-append');
    end
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

