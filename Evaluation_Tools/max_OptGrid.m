classdef max_OptGrid < method_max
%MAX_OPTGRID - look for optimal plateau using the approximate permutation
%                        test. Use sparse sampling to reduce evaluations.
%
%   The max_OptGrid class is used to find the optimal volume
%   point by finding the plateau. An optimal volume plateau identification
%   algorithm (OVPIA). The approximate permutation test is used
%   to determine if points come from the same distribution and return the
%   center of a region where all points are from the same distribution.
%
%MAX_OPTGRID Methods:
%   init     - clear saved data and get first value to evaluate
%   get_next - get next value based on results of current and previous
%              evaluations
%   get_opt  - get the optimum point determined by the algorithm
%
%MAX_OPTGRID Read Write Properties
%   name   -  method name
%   range  - range to search over
%   tol    - tolerance used for end condition
%   points - number of points in initial sampling
%
%
%MAX_OPTGRID Read Only Properties
%   a          - Lower end point of current interval
%   b          - Upper end point of current interval
%   eval_step  - how many evaluations have been done so far
%   start_step - which step the current grid was first evaluated on
%   grid       - current set of points that are being evaluated
%   spacing    - spacing between grid points
%   y_values   - all y values that have been evaluated so far
%   x_values   - all x values that y values have been evaluated at so far
%   winFound   - logical value true if initial window has been found
%   dither     - standard deviation noise level to add to input points
%
%   see also method_max, maxTest
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



    properties
%POINTS - number of points in initial sampling
        points
%DITHER - standard deviation noise level to add to input points
        dither=0.05;
    end    
    
    properties(Hidden=true,SetAccess=protected)
%   A - Lower end point of current interval
        a
%   B - Upper end point of current interval
        b
%   EVAL_STEP - how many evaluations have been done so far
        eval_step
%   START_STEP - which step the current grid was first evaluated on
        start_step
%   GRID - current set of points that are being evaluated
        grid
%   SPACING - spacing between grid points
        spacing
%   Y_VALUES - all y values that have been evaluated so far
        y_values
%   X_VALUES - all x values that y values have been evaluated at so far
        x_values
%   WINFOUND - logical value true if initial window has been found
        winFound;
%   GROUPS - cell array of group indicies
        groups;
%   CHOSEN_GROUP - the group that is used to set the interval
        chosen_group;
    end
    
    methods
        
        function obj=max_OptGrid(np)
            if(exist('np','var') && ~isempty(np))
                obj.points=np;
            else
                %default to 10 points
                obj.points=10;
            end
        end
        
        function x_val=init(obj)
% INIT - reset internal values to start a new evaluation
            
            %set initial limits from range
            obj.a=obj.range(1);
            obj.b=obj.range(2);
            %start at step zero
            obj.eval_step=0;
            %reset stored data
            obj.y_values={};
            obj.x_values=[];
            obj.winFound=0;
            obj.groups={};
            obj.chosen_group=NaN;
            %set grid based on limits and number of points
            obj.setup_grid();
            %get the first eval point
            x_val=obj.get_eval();
        end
        
        function setup_grid(obj)
% SETUP_GRID - populate array of x-values to evaluate at

            %check if this is the first grid
            if(obj.eval_step==0)
                %generate a linear grid over the interval with the given
                %number of points
                obj.grid=linspace(obj.a,obj.b,obj.points);
                %get spacing from grid
                obj.spacing=mean(diff(obj.grid));
            else
                %set new spacing
                obj.spacing=obj.spacing/2;
                %check if we have an initial grid
                if(obj.winFound)
                    %sample points around edge points
                    ng=[obj.a-obj.spacing,obj.a+obj.spacing,obj.b-obj.spacing,obj.b+obj.spacing];
                else
                    %generate new grid on interval with new spacing
                    ng=(obj.a):obj.spacing:(obj.b);
                end
                %preallocate
                rpt=zeros(size(ng),'logical');
                %find repeat points
                for k=1:length(ng)
                    %consider 2 points the same if they are closer than 1
                    %100th of the spacing
                    %were getting rounding errors otherwise
                    rpt(k)=any(abs(ng(k)-obj.x_values)<obj.spacing/100);
                end
                %set new grid skipping repeats
                obj.grid=ng(~rpt);
            end
            obj.start_step=obj.eval_step;
        end

        function v=get_eval(obj)
% GET_EVAL - return the next x-value to evaluate at

            %check for empty grid
            if(isempty(obj.grid))
                %return NaN cause we don't have a value
                v=NaN;
            else
                %return the next value from the grid
                v=obj.grid((obj.eval_step-obj.start_step)+1);
            end
        end
        
        function [x_val,done]=get_next(obj,eval_x,y_vals)
% GET_NEXT get the next x value to evaluate at based on new data

            %set to next step
            obj.eval_step=obj.eval_step+1;
            %save data with dither noise
            obj.y_values{obj.eval_step}=y_vals+random('Normal',0,obj.dither,size(y_vals));
            obj.x_values(obj.eval_step)=eval_x;
            %check if we need a new grid
            if((obj.start_step+length(obj.grid))==obj.eval_step)
                
                for k=(obj.start_step+1):obj.eval_step
                    
                    if(isempty(obj.groups))
                        obj.groups{1}=k;
                    else
                        found=0;
                        for kk=1:length(obj.groups)
                            if(approx_permutation_test(obj.y_values{k},[obj.y_values{obj.groups{kk}}]))
                                obj.groups{kk}=[obj.groups{kk} k];
                                %found! done
                                found=1;
                                break;
                            end
                        end
                        if(~found)
                            %not found, add new group
                            obj.groups{end+1}=k;
                        end
                    end
                end
                
                %get group length
                group_size=cellfun(@length,obj.groups);
                
                mean_y=zeros(size(group_size));
                
                for k=1:length(obj.groups)
                    %compute the mean of y-values
                    mean_y(k)=mean(mean([obj.y_values{obj.groups{k}}]));
                end
                
                g_score=mean_y.*group_size;
                
                %check max group size
                if(max(group_size)>1)

                    %find which score is max
                    [~,obj.chosen_group]=max(g_score);

                    %get sorted x-values
                    group_x=sort(obj.x_values(obj.groups{obj.chosen_group}));
                    
                    %we have a group with multiple points, window found
                    obj.winFound=true;
                    %set current interval from group
                    obj.a=group_x(1);
                    obj.b=group_x(end);
                end
                    
                %new grid
                obj.setup_grid();
                %check grid size
                done=obj.spacing<obj.tol;                
            else
                done=false;
             end
            %get next eval point
            x_val=obj.get_eval();
        end
        
        function [opt]=get_opt(obj)
% GET_OPT - return the optimal point
%
%   The optimal point is defined as the point 4/5 away from the lower part of of the current interval
%   of interest

            %get group length
            group_size=cellfun(@length,obj.groups);
            %check that we have groups and not individuals
            if(max(group_size)>1)
                fprintf('Optimal interval : [%f,%f]\n',obj.a,obj.b);
                % Set the opt value to be 4/5 of the way in the interval
                Int_Length = abs(obj.a - obj.b);
                opt = obj.a + (Int_Length*(4/5));
            else
                warning('No groups formed. Optimal interval not found.')
                opt=NaN;
            end
        end
                
    end
    
end
