function MaxMethod_Check(varargin)
%MaxMethhod_Check Take in a CSV of project data. Create 
% a model from this data. Run it through max_OptGrid, and get information 
% about behavior. A variety of parameters can be specified to meet 
% evaluation needs. Output options include information on mean and standard
% deviation values of the data; plots of decisions across eval points; 
% plots of the final optimal values with intervals; plots of the groups 
% across eval points.
%
% MaxMethod_Check(name, value) Possible name value pairs are shown below:
%
% NAME          TYPE            Description
% 
% Dat_Path      string          Path to data file (CSV)
%
% NumIt         double          Number of iterations/trials to run
%
% Noise         double          Noise value to apply to data (equal at all
%                               points)
%
% NumPoints     double          Number of initial points
%
% Tol           double          Min space between eval points
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

%% Input parsing
% Create input parser
p = inputParser();

% Optional CSV file parameter 
addParameter(p,'Dat_Path',[],@(d)validateattributes(d,{'char','string'},{'scalartext'}));
% Optional number of initial points parameter
addParameter(p,'NumPoints',10,@(t)validateattributes(t,{'numeric'},{'scalar','positive'}));
% Optional number of iterations parameter 
addParameter(p,'NumIt',10,@(t)validateattributes(t,{'numeric'},{'scalar','positive'}));
% Optional tol setting parameter
addParameter(p,'Tol',1,@(t)validateattributes(t,{'numeric'},{'scalar','positive'}));
% Optional noise setting parameter 
addParameter(p,'Noise',0.0561,@(t)validateattributes(t,{'numeric'},{'scalar','positive'}));

% parse inputs
parse(p,varargin{:});

% Define main variables from input
 InitialPoints = p.Results.NumIt;
 mm =  max_OptGrid(InitialPoints);
 Noise = p.Results.Noise;
 dat = p.Results.Dat_Path;
 NumIt = p.Results.NumIt;
 Tol = p.Results.Tol;
  
%% Create Model
[mod_FSF,std_FSF]=model_gen(dat);

%% Run maxTest, get useful data from each run
for n = 1:NumIt
    % Run maxTest
    [opt,x,y,dat_idx,test_dat]=maxTest(mm,@(q)mod_FSF(q),[-40,0],'maxIttr',200,'noise', Noise,'Trials',40,'tol',Tol);
    % Save the final Opt and interval values for each run
    Opt(n) = opt;
    Interval{n} = [mm.a,mm.b];
    IntLow(n) = Interval{1,n}(1);
    IntHigh(n) = Interval{1,n}(2); 
    NumPoints(n) = length(unique(x));
    % Save the Opt, A, and B values for each evaluation point for each run
    for m = 1:NumPoints(n)   
         OptIndiv(m) = (test_dat.max_dat(1,m).get_opt);
         IndivA(m) = test_dat.max_dat(1,m).a;
         IndivB(m) = test_dat.max_dat(1,m).b;
    end 
    detailsOpt{n} = OptIndiv;
    detailsA{n} = IndivA;
    detailsB{n} = IndivB;
% Get plots of group evaluations across eval points 
PlotGroups(NumPoints,test_dat,n,NumIt);
end    

%% Run the following checks with individual functions: 
% Get the mean and standard deviation values
GetDetails(Opt,IntLow, IntHigh, NumPoints)
% Get plots of O, A, B for each trial across eval points
PlotOAB(detailsOpt,detailsA,detailsB,NumIt)
% Get plots of final Opt and interval values shown as error bars
PlotFinal(Opt,IntLow,IntHigh,NumIt)

end

%% =========[Get Mean, Standard Deviation]==========
% Calculate the mean ideal transmit volume setting, lower interval, upper 
% interval, number of evaluated points. Then get the standard deviation. 
function GetDetails(Opt,IntLow, IntHigh, NumPoints)    
% Ideal volume setting
Ideal_Mean = mean(Opt)
% Standard deviation
Ideal_SD = std(Opt)
% Mean lower interval value
MeanLow = mean(IntLow)
% Mean upper interval value
MeanUpper = mean(IntHigh) 
% SD of upper and lower interval values
MeanLow_SD = std(IntLow)
MeanUpper_SD = std(IntHigh)
% Mean number of evaluated points
NumPointsMean = mean(NumPoints)
end
    
%% =========[Plot Opt, A, and B]==========
% Plot the values of Opt, A, and B at all evaluation points for each run 
function PlotOAB(detailsOpt,detailsA,detailsB,NumIt)
for n = 1:NumIt
    % Plot Opt across eval points
     figure(NumIt+10)     
     plot(detailsOpt{1,n}, '-')
     hold on
     grid on
     title('Ideal Values at Eval Points')
     xlabel('Point Number')
     ylabel('Ideal Value (dB)')
     legend('Opt')
     % Plot lower interval value A across eval points
     figure(NumIt+11)
     plot(detailsA{1,n}, '-')
     hold on
     grid on
     title('Ideal A Values at Eval Points')
     xlabel('Point Number')
     ylabel('Ideal Value (dB)')
     legend('A (Lower Interval)')
     % Plot upper interval value B across eval points
     figure(NumIt+12)
     plot(detailsB{1,n}, '-')
     hold on
     grid on
     title('Ideal B Values at Eval Points')
     xlabel('Point Number')
     ylabel('Ideal Value (dB)')
     legend('B (Upper Interval)')
end     
end
 
%% =========[Plot Final Values]==========
% Plot the final Opt output as well as the interval values in the style of
% error bars 
function PlotFinal(Opt,IntLow,IntHigh,NumIt)
 figure()     
 ypos = IntHigh-Opt;
 yneg = IntLow-Opt;
 errorbar([1:NumIt],Opt,yneg,ypos,'o')
 grid on
 title('Ideal VTX Values and Intervals')
 xlabel('Trial Number')
 ylabel('Ideal Value (dB)')
end

%% =========[Group Plots]==========
% Plot the progression of group selection at all evaluation points for each
% run
function PlotGroups(NumPoints,test_dat,n, NumIt)
for m = 1:NumPoints(n) 
    % Get the group information from test dat, determine spacing
    figure(n+NumIt+20);
    hold on;
    groupsIndv{m} = test_dat.max_dat(m).groups;  
    x_vals=test_dat.max_dat(m).x_values;
    spacing=test_dat.max_dat(m).spacing;
    step=m;
    group_colors=lines(length(groupsIndv{m}));
    for k=1:length(groupsIndv{m})
        group_x=x_vals(groupsIndv{1,m}{1,k});
        mx=max(group_x);
        mn=min(group_x);
        if(mn==mx)
            mx=mx+spacing*0.8;
            mn=mn-spacing*0.8;
        end
        % Plot groups
        fill(step+[-0.4,0.4,0.4,-0.4],[mn,mn,mx,mx],group_colors(k,:),'FaceAlpha',0.85,'EdgeColor','none','DisplayName',sprintf('Group #%u',k))
    end
    xlim([0,22])
    xlabel('Evaluation step');
    ylabel('Volume [dB]');
    title('Groups at Evaluation Points')
end  
end    