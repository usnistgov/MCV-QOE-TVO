function [mod_FSF,std_FSF]=model_gen(filename)
%MODEL_GEN generate interpolant from volume data
%   mod=MODEL_GEN(FILE) generates an interpolant from the volume points in
%   FILE. FILE should be a .csv file as produced by export_data2csv or
%   export_data2csv_M4. mod is an interpolant that gives FSF scores as a
%   function of volume.
%
%   [mod,std_dat]=MODEL_GEN(FILE) same as above except the standard
%   deviation is given at each volume level used to make mod.
%
%see also export_data2csv, export_data2csv_M4


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

    %read data
    dat=readtable(filename);
    
    %check if we found a Volume_levels column
    if(~any(strcmp(dat.Properties.VariableNames,'Volume_levels')))
        %no, this is M4 data, skip the original header format
        dat=readtable(filename,'HeaderLines',2);
    end
    
    %find the unique volume levels
    volumes=unique(dat.Volume_levels_dB_);
    
    %preallocate
    fsf_avg=zeros(size(volumes));
    std_FSF=zeros(size(volumes));
    
    for k=1:length(volumes)
        %find all the matching data
        idx=dat.Volume_levels_dB_==volumes(k);
        %calculate mean for this volume
        fsf_avg(k)=mean(dat.FSF(idx));
        %calculate the standard deviation at this volume
        std_FSF(k)=std(dat.FSF(idx));
    end
    
    %interpolate the data to get the model
    mod_FSF=griddedInterpolant(volumes,fsf_avg,'spline','linear');