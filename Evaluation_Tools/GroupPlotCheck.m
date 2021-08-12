function GroupPlotCheck(varargin)
%GroupPlotCheck Read in CSV data files from the volume project.
% Use model_gen to create models based on data. Run maxTest to get interval
% data. Plot the intervals found by the grouping method to see more details
% about the decision making process that leads to the final selected 
% optimal interval. 
%
% GroupPlotCheck(name, value) Possible name value pairs are shown below:
%
% NAME          TYPE            Description
% method        string          Name of selection method to test if
%                               checking something besides default.
%
% dith_val      double          If testing impact of other dither values, 
%                               this can be used.
%
% mod_noise     double          Noise value to set for the model. 
%
% CSV_dat       string          File path for CSV of project data.
%
% num_it        double          Number of iterations of maxTest.
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
%

%% Input parsing
% Create input parser
p = inputParser();
% Optional method name parameter
addParameter(p,'method',[max_OptGrid(10)],@(d)validateattributes(d,{'char','string'},{'scalartext'}));
% Optional dither value parameter
addParameter(p,'dith_val',0.05,@(t)validateattributes(t,{'numeric'},{'scalar','positive'}));
% Optional model noise parameter. Default is the average of values tested
% in early project phases using the model.
addParameter(p,'mod_noise',0.0561,@(t)validateattributes(t,{'numeric'},{'scalar','positive'}));
% Optional input file directory parameter
addParameter(p,'CSV_dat',[],@(d)validateattributes(d,{'char','string'},{'scalartext'}));
% Optional dither value parameter
addParameter(p,'num_it',5,@(t)validateattributes(t,{'numeric'},{'scalar','positive'}));

parse(p,varargin{:});

%% Load input parameters 
% mm and Noise will change. Enter the required method and value. 
 mm = p.Results.method;
 mm.dither = p.Results.dith_val;
 Noise = p.Results.mod_noise;
 dat = p.Results.CSV_dat;
 num_it = p.Results.num_it;

%% Create model data 
disp('Generating models')
[mod_FSF,std_FSF]=model_gen(dat);

%% Run maxTest for the model data multiple times. Plot the simulated test 
% data and group algorithm progression across iterations.
disp('Running maxTest iterations')
for n = 1: num_it
    [opt,x,y,dat_idx, test_dat]=maxTest(mm,@(q)mod_FSF(q),[-40,0],'maxIttr',200,'noise', Noise,'Trials',40,'tol',1);
    ax1 = gca;
    xlabel('Volume [dB]');
    ylabel('FSF Score');
    title('maxTest Data')
   
    Opt(n) = opt;
    Interval{n} = [mm.a,mm.b];
    IntLow(n) = Interval{1,n}(1);
    IntHigh(n) = Interval{1,n}(2); 
    NumPoints(n) = length(unique(x));
    
       figure()
       hold on;
    for m = 1:NumPoints(n) 
       % figure()
        %hold on;
        groupsInv{m} = test_dat.max_dat(m).groups;  
        x_vals=test_dat.max_dat(m).x_values;
        spacing=test_dat.max_dat(m).spacing;
        step=m;
        group_colors=lines(length(groupsInv{m}));
        for k=1:length(groupsInv{m})
            group_x=x_vals(groupsInv{1,m}{1,k});
            mx=max(group_x);
            mn=min(group_x);
            if(mn==mx)
                mx=mx+spacing*0.8;
                mn=mn-spacing*0.8;
            end
            fill(step+[-0.4,0.4,0.4,-0.4],[mn,mn,mx,mx],group_colors(k,:),'FaceAlpha',0.85,'EdgeColor','none','DisplayName',sprintf('Group #%u',k))
        end
        xlim([0,22])
        xlabel('Evaluation Step');
        ylabel('Volume [dB]');
        title('Groups at Eval Points')
        ax2 = gca;
    end
    groups{n} = groupsInv;
   % Combine plots to have one window of plots per run of evalTest
   % Based on matlab subplot documentation
    fnew = figure;
    ax1_copy = copyobj(ax1,fnew);
    subplot(2,1,1,ax1_copy)
    copies = copyobj([ax2],fnew);
    ax2_copy = copies(1);
    subplot(2,1,2,ax2_copy)
end
% Show Opt values
disp('Opt values (dB):')
fprintf('%f\n',Opt);