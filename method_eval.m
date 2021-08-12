classdef (Abstract) method_eval
%METHOD_EVAL - abstract class for method evaluation objects
%
%   The METHOD_EVAL class is defined for use with evalTest. To define
%   evaluation methods that need to load static data or define
%   parameterized methods. 
%
%METHOD_EVAL Methods:
%   process - the process is an abstract method of METHOD_EVAL a
%             subclass of method_eval must implement this method. 
%
%METHOD_EVAL Properties:
%   name -  method name.

%   See also EVALTEST.
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
%NAME -  method name. This is used by evalTest and others for things
%        like plot legends. It is set, by default, to the class of the
%        object and can be overridden as needed. This is useful when
%        running a test where different options of the same name.
        name 
    end
    methods (Abstract)
%PROCESS - compute score for a set of recordings
%
%   process(rec,y,clipi,cutpoints) computes the score given a cell array of
%   recorded clips, rec, original clips, y, array of indices of original
%   clips, clipi, and cutpoints (if available) for MRT keywords, cutpoints.
%   Process returns a scalar value, score, that represents how "good" the
%   recordings are.
        score=process(obj,rec,y,clipi,cutpoints)
    end
    methods
        function obj=method_eval()
            obj.name=class(obj);
        end
    end
end
        