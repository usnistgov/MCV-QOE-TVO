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
        