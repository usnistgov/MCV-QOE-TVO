classdef (Abstract) method_max < handle & matlab.mixin.Copyable
%METHOD_MAX - abstract class for method evaluation objects
%
%   The METHOD_MAX class is defined for use with maxTest. This allows max
%   finding methods to be tested and compared.
%
%METHOD_MAX Methods:
%   init     - clear saved data and get first value to evaluate at
%   get_next - get next value based on results of current and previous
%              evaluations
%   get_opt  - get the optimum point determined by the algorithm.
%
%METHOD_MAX Properties:
%   name  -  method name.
%   range - range to search over
%   tol   - tolerance used for end condition
%
%   See also maxTest.
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


    properties
%NAME -  method name. This can be used for things like plot legends. It is
%        set, by default, to the class of the object and can be overridden
%        as needed. This is useful when running a test where different
%        options of the same.
        name 
        range(1,2) {mustBeNumeric,mustIncrease}=[-inf,inf]
        tol(1,1)   {mustBeNumeric,mustBeFinite,mustBePositive}=0.1
    end
    methods (Abstract)
%INIT - clear saved data and get first value to evaluate at
        x_val=init(obj)
%GET_NEXT - get next value based on results of current and previous
%           evaluations
        [x_val,done]=get_next(obj,eval_x,y_vals)
%GET_OPT - get optimal value based on current data
        [opt]=get_opt(obj)
    end
    methods
        function obj=method_max()
            obj.name=class(obj);
        end
    end
end
        
%helper function for tol validation
function mustIncrease(dat)
    if(~all(diff(dat)>0))
        error('Values must be increasing')
    end
end
