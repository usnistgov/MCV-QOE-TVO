function [opt,x,y,dat_idx, test_dat]=maxTest(method,func,range,varargin)
%MAXTEST - maximum finding method test
%
%   MAXTEST(method,function,range) runs the method, subclass of method_max,
%       on the func func over the range, given by range. Returns the
%       optimum point
%
%   [opt,x,y,dat_idx]=MAXTEST(__) same as above but also returns the x and
%       y values and run index that the data originated at.
%
%   MAXTEST(__,name,value) same as above but specifies one or more name,
%       value pairs. Possible options are listed below:
%
%   name        Type                description
%   =======================================================================
%
%   noise       numeric scalar      Standard deviation of normally
%                                   distributed noise that is added to the
%                                   function values. Default, 0.
%
%   recycle     logical             When true, don't re-evaluate function
%                                   and re-add noise, just use previously
%                                   computed values. Default, false.
%
%   maxIttr     numeric scalar      Maximum number of iterations to run.
%                                   defaults to 50.
%
%   Trials      numeric scalar      Number of evaluations to do at each x
%                                   value. Default, 1.
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

    %% ======================[Parse Input Arguments]======================

    %create new input parser
    p=inputParser();

    %add method argument
    addRequired(p,'method',@(m)validateattributes(m,{'method_max'},{'scalar'}));
    addRequired(p,'func',@(f)validateattributes(f,{'function_handle'},{'scalar'}));
    addRequired(p,'range',@(r)validateattributes(r,{'numeric'},{'vector','numel',2,'increasing'}));
    
    %add noise level parameter
    addParameter(p,'noise',0,@(l)validateattributes(l,{'numeric'},{'real','finite','scalar','nonnegative'}));
    %add recycle parameter
    addParameter(p,'recycle',false,@(l)validateattributes(l,{'logical','numeric'},{'scalar'}));
    %add iteration limit parameter
    addParameter(p,'maxIttr',50,@(l)validateattributes(l,{'numeric'},{'real','finite','scalar','positive'}));
    %add number of trials per volume level parameter
    addParameter(p,'Trials',1,@(t)validateattributes(t,{'numeric'},{'scalar','positive','integer'}));
    %add tolerance parameter
    addParameter(p,'tol',0,@(t)validateattributes(t,{'numeric'},{'scalar','nonnegative','finite'}));

    %parse inputs
    parse(p,method,func,range,varargin{:});
    
    %% ========================[preallocate arrays]========================
    
    x=NaN(p.Results.maxIttr,1);
    y=NaN(p.Results.maxIttr,p.Results.Trials);
    dat_idx=zeros(p.Results.maxIttr,1);

    %% ========================[Initialize method]========================
    
    %set tolerance
    if(p.Results.tol>0)
        method.tol=p.Results.tol;
    end
    %set range
    method.range=range;
    %initialize method
    x(1)=method.init();
    
    %% =========================[Simulation Loop]=========================
   
    for k=1:p.Results.maxIttr
        idx=find(x(1:(k-1))==x(k),1,'first');
        if(isempty(idx) || k==1 || (~p.Results.recycle))
            %print message for each point
            fprintf('Evaluating at x = %f\n',x(k));
            y(k,:)=func(x(k))+random('Normal',0,p.Results.noise,p.Results.Trials,1);
            dat_idx(k)=k;
        else
            %print message for each point
            fprintf('Duplicate detected, recycling from x = %f\n',x(k));
            y(k,:)=y(idx,:);
            dat_idx(k)=idx;
        end
        [x(k+1),done]=method.get_next(x(k),y(k,:));
        test_dat.max_dat(k)=copy(method);
        if(done)
            break;
        end
    end
    
    %remove extra elements from arrays
    x=x(1:k);
    y=y(1:k,:);
    dat_idx=dat_idx(1:k);
    
    %% ====================[evaluate function for plot]====================
    
    f_x=linspace(range(1),range(2),100);
    f_y=arrayfun(func,f_x);
    
    %% ========================[Get optimal value]========================
    
    opt=method.get_opt();
    
    %% ===========================[Plot Results]===========================
    
    figure;
    
    plot(f_x,f_y,'DisplayName','Function');
    
    hold on
    x_rep=repmat(x,1,p.Results.Trials);
    plot(x_rep(:),y(:),'o','DisplayName',sprintf('%s eval points',method.name));
    
    if(p.Results.Trials>1)
        y_mean=mean(y,2);
        
        plot(x,y_mean,'X','DisplayName','eval mean','MarkerSize',10,'LineWidth',2);
        
        y_std=std(y,0,2);
        
        plot(x,y_mean+1.96*y_std,'d','DisplayName','uncertainty upper bound','MarkerSize',10,'LineWidth',2);
        plot(x,y_mean-1.96*y_std,'d','DisplayName','uncertainty lower bound','MarkerSize',10,'LineWidth',2);
        
        
    end
    
    xline(opt,'DisplayName','Max estimate')
    [~,f_max_idx]=max(f_y);
    xline(f_x(f_max_idx),'DisplayName','Max data','LineStyle',':')
    
    legend('Location','NorthEast','Interpreter','none');
    
end