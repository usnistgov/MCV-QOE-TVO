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


classdef eval_MRT < method_eval
    properties
        MRT_obj
        TimeExpand=0;
    end
    methods
        function obj=eval_MRT()
            %initialize MRT object
            obj.MRT_obj=ABC_MRT16();
        end
        function score=process(obj,rec,y,clipi,cutpoints)
            fs=48e3;
            max_words=max(cellfun(@(a)size(a,1),cutpoints));
            
            %preallocate! for speed
            mrt_w=zeros(size(rec));
            success=zeros(max_words,length(rec));
            
            for k=1:length(rec)

                %expand cutpoints by TimeExpand
                ex_cp=round(cutpoints{clipi(k)}(:,[2,3]) -  (obj.TimeExpand*fs).*[1,-1]);

                %limit cutpoints to clip length
                ylen=length(y{clipi(k)});
                ex_cp(ex_cp>ylen)=ylen;

                %minimum cutpoint index is 1
                ex_cp(ex_cp<1)=1;

                %check for NaN's in cutpoints
                valid=~isnan(cutpoints{clipi(k)}(:,1));

                %split file into clips, skip any NaN values
                dec_sp=arrayfun(@(s,e)rec{k}(s:e)',ex_cp(valid,1),ex_cp(valid,2),'UniformOutput',false);
                
                %compute MRT scores for clips
                [mrt_w(k),success(valid,k)]=...
                    obj.MRT_obj.process(dec_sp,cutpoints{clipi(k)}(valid,1));

            end
            %compute average score and return 
            score=mrt_w;
        end
    end
end