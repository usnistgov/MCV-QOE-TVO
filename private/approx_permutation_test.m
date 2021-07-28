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

function [equiv,reps,observed_diff] = approx_permutation_test(x1,x2,varargin)
%% Input parsing
p = inputParser();
addRequired(p,'x1');
addRequired(p,'x2');

addParameter(p,'R',10000,@(n) validateattributes(n,{'numeric'},{'scalar','positive','integer'}));
addParameter(p,'rho',0.95, @(n) validateattributes(n,{'numeric'},{'scalar','>',0,'<',1}));

addParameter(p,'statistic',@mean,@(x) isa(x,'function_handle'));
addParameter(p,'plot',false,@(n) validateattributes(n,{'logical','numeric'},{'scalar'}));

parse(p,x1,x2,varargin{:});

% Number of replications to run
R = p.Results.R;
% Defines Confidence level (defaults to 95%)
rho = p.Results.rho;
% Statistic to use to compare samples (defaults to mean)
statistic = p.Results.statistic;
%%
% Initialize replications array
reps = zeros(R,1);

% Number of observations in each data set
n1 = length(x1);
n2 = length(x2);
% Total number of observations
n = n1+n2;

% Combine two datasets
combined_data = [x1(:); x2(:)];
for k = 1:R
    % Random permutation of 1:n
    perm = randperm(n);
    
    % Randomly select n1 elements to replicate x1
    rep1 = combined_data(perm(1:n1));
    % Randomly select n2 elements to replicate x2
    rep2 = combined_data(perm((n1+1):end));
    
    % Store difference in statistic between two groups
    reps(k) = statistic(rep1) - statistic(rep2);
end

% Calculate actual observed difference
observed_diff = statistic(x1(:)) - statistic(x2(:));

% Lower bound of confidence interval quantile
q_low = (1 - rho)/2;
% Upper bound
q_high = 1 - q_low;

% Calculate rho based quantile bounds for replication results
rep_q = quantile(reps,[q_low,q_high]);

% If observed value lies within quantile: accept equivalence
if(rep_q(1) <= observed_diff && observed_diff <= rep_q(2))
    equiv = true;
else
    equiv = false;
end

% Plot to show distribution of replication statistics vs observed value
if(p.Results.plot)
   figure
   histogram(reps)
   hold on
   xline(rep_q(1),'--k');
   xline(rep_q(2),'--k');
   xline(observed_diff,'r','LineWidth',2);
   
   xlabel('Difference of statistic values')
   ylabel('Frequency')
   
   legend('replications','Quantile LB','Quantile UB','Observed Value')
end
end