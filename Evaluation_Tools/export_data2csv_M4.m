function export_data2csv_M4(varargin)
% Reads Volume Adjust .mat data files and creates a CSV. CSV files can be
% used for quick analysis in multiple software packages. 

% export_data2csv_M4(name, value) Possible name value pairs are shown below:
%
% NAME          TYPE            Description
% 
% Dat_Dir       string          File path where data lives
%
% Dat_Name      string          Name of test file (.mat)
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

% Optional data directory parameter
addParameter(p,'Dat_Dir',[],@(d)validateattributes(d,{'char','string'},{'scalartext'}));
% Optional data file name parameter 
addParameter(p,'Dat_Name',[],@(d)validateattributes(d,{'char','string'},{'scalartext'}));

% parse inputs
parse(p,varargin{:});

% Path where data stored
dat_path = fullfile(p.Results.Dat_Dir);
Dat_Name = p.Results.Dat_Name;
Dat_File = strcat(p.Results.Dat_Name,'.mat');
% Cell array with following columns:
% Test Type, Test name, File/folder Path
data_info = {'Volume Adjust', Dat_Name, fullfile(dat_path,Dat_File)};

% Create instances of eval_FSF
FSF_Calc = eval_FSF();

for t_ix = 1:size(data_info,1)
    % Get data file name
    dat_name = data_info{t_ix,3};
    % Load dat info 
    vdat = load(dat_name);
    volume_levels = vdat.test_dat.volume;
    test_files = dat_name;

    % Call evalTest
    [fsf_values] = evalTest(test_files,{FSF_Calc},...
        'ClipPath','C:\Users\cjg2\Documents\MCV\Audio-Clips\',...
        'XVals',volume_levels,...
        'XLabel','Volume',...
        'OneAtATime',true);
    % Grab FSF values
    fsf_vals = cell2mat(fsf_values(:,1))';
    % Get final Opt value using the final 0.8 weight
    Int_Length = abs(vdat.method.a - vdat.method.b);
    Opt_Val = vdat.method.a + (Int_Length*(4/5))
    % Get upper and lower intervals
    Upper_Val = vdat.method.b;
    Lower_Val = vdat.method.a;
    
    % Initialize matrix to store all data in
    data = zeros(numel(fsf_vals),2);
    for k = 1:length(volume_levels)
        % Grab volume level
        vol_lvl = volume_levels(k);
        % Grab indices to store data in
        data_ix = (k-1)*size(fsf_vals,1)+(1:size(fsf_vals,1));
        % Store volume level
        data(data_ix,1) = vol_lvl;
        % Store FSF values
        data(data_ix,2) = fsf_vals(:,k); 
    end
    
    % Create a table of results
    table_out = table(data(:,1),... % Volume levels
        data(:,2),... % FSF
       'VariableNames',{'Volume_Levels [dB]','FSF'});
    test_type = data_info{t_ix,1};

    % Define output directory for this post-processed data
    output_dir = fullfile('Post-processed data',test_type);
    
    % Make output directory if it doesn't exist
    if(~exist(output_dir,'dir'))
        mkdir(output_dir)
    end
    
    % File name
    test_name = sprintf('%s.csv',data_info{t_ix,2});

    % Create CSV header
    fid = fopen(test_name,'w');
    fprintf(fid,'Optimal [dB], Lower_Interval [dB], Upper_Interval [dB]\n');
    fprintf(fid,'%d,%d,%d\n',Opt_Val,Lower_Val,Upper_Val);

    % Add table info the the csv
    fprintf(fid,'Volume_levels [dB],FSF\n');
    table_dat = table2array(table_out);
    fprintf(fid,'%d,%d\n',table_dat');
    fclose(fid);
    
    % Path to save post-processed data to
    test_path = fullfile(output_dir,test_name);
    
end
