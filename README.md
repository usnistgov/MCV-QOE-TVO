# Summary
The purpose of this software is to find the optimal transmit volume for a push-to-talk (PTT) communications device for a system under test (SUT) using a transmit volume optimization (TVO) tool. TVO  should be performed for every combination of PTT device under test and every audio file used in performing Mission Critical Voice (MCV) quality of experience (QoE) measurements.  

## Obtaining Software
- Code available at:
- Data available at:
- Paper available at:

## Hardware Requirements 
- See **Link to paper** and Mission Critical Voice QoE Access Time Measurement Methods https://www.nist.gov/ctl/pscr/mission-critical-voice-qoe-access-time-measurement-methods

## Software Requirements
- MATLAB R2019a or newer with the following toolboxes:
	- Audio System Toolbox (Audio Toolbox on R2019a and newer)
	- Signal Processing Toolbox
- R version 3.5.X or newer
    - RStudio (recommended)
	- ggplot2, minpack.lm packages (will install on accessTime package install)
    - devtool package (must be installed via `install.packages("devtools")` )

# Running TVO Tests
The software is divided into subfolders for the type of test that is being performed. The main directory contains code needed to run a TVO. For additional setup information please refer to doccumentation in the paper. 

To run the TVO, run the volume_adjust.m script. Speech will be played and recorded using the connected audio device. The data is stored in a subfolder named data/. 

volume_adjust.m takes in a variety of optional input paramaters. Default input may be used. Advanced users may be interested in specifying some input paraters. Parameters that may be customized include:
- AudioFile: audio file to be used for performing tests.
- Trials: Number of trials to run for each sample volume.
- Volumes: Instead of using the algorithm to determine what volume levels to     sample,explicitly set the volume sample points. When this is given no optimal volume is calculated.
- Lim:  Lim sets the volume limits to use for the test in dB. 
- PTTGap: Time to pause after completing one trial and starting the next. This setting may need to change if one is using a SUT with broadband. 
- tol: Tolerance value used to set minimum spacing between evaluated volume levels.

## Example input specifications:
- volume_adjust
- volume_adjust('AudioFile', 'Filepath\My_Test.wav', 'Trials', 80, 'Lim', [-30,-10],'tol',2)
 
There are additional scripts in the main directory. These are used to run the main componenents of the TVO. The folder *private* contains additional helper functions to run this measurement.

# Audio Files
Audio files can be found in the 'clips' folder. By default, all four of these audio files are used. The csv files with cutpoints, as well as the test wav files, are included. 

# Statistical Analysis
The scripts in **FOLDER** contain 

# Additional Tools
The scripts in **FOLDER** are used for users interested in further evaluating data. There are a variety of post-processing tools to view details of data, the TVO elements, and perform simulations.

## evalTest
Post-processing tool used to run an evaluation function on test data, such as eval_FSF. This is useful for reviewing the FSF scores individually, not just the averages, and evaluating behavior. 
### Example input specifications:
- To evaluate data and view/plot individual FSF scores: evalTest('\\directory\data\capture_M4-Analog-Direct_01-Dec-2020_07-09-01.mat',eval_FSF(),'OneAtATime',true)


## eval_MRT.m 
Used to perform ABC-MRT16 calculations across evaluated volume levels. This is used in either **volume_adjust** or **evalTest**. 

### Example use case:
evalTest('\\directory\data\capture_M4-Analog-Direct_01-Dec-2020_07-09-01.mat',eval_MRT(),'OneAtATime',false)

## model_gen 
Used to generate an interpolant from the volume points in a .csv data file. Mod is an interpolant that gives FSF scores as a function of tranmit volume levels. Standard deviation is given at each volume level used to make mod.
### Example input specifications:
[mod,std_dat]=model_gen(\\directory\data\capture_M4-Analog-Direct_01-Dec-2020_07-09-01.csv')

## maxTest 
Runs the method, subclass of method_max, on the func func over the range, given by range. Returns the optimum transmit volume level. 

### Example input specifications:
[opt,x,y,dat_idx, test_dat]=maxTest(mm,@(q)mod_FSF(q),[-40,0],'maxIttr',200,'noise', Noise,'Trials',40,'tol',1);


## maxmethod_check 
Take in a CSV of project data. Create a model from data. Run it through max_OptGrid, and get information about behavior. Output options include information on mean and standard deviation values of the data; plots of decisions across eval points; plots of the final optimal values with intervals; plots of the groups across eval points.

### Example input specifications:
MaxMethod_Check('Dat_Path', '\directory\data\capture_M4-extra_31-Dec-2020_10-44-42.csv', 'Tol',2, 'Noise', 0.3)

## GroupPlotCheck 
Read in CSV data files. Use model_gen to create models based on data. Run maxTest to get interval data. Plot the intervals found by the grouping method to see more details about the decision making process that leads to the final selected optimal interval. 

### Example input specifications:
GroupPlotCheck('CSV_dat', '\directory\data\Analog Direct\capture_M4-extra_31-Dec-2020_10-44-42.csv')

## distortSim 
Simulate volume optimization with noise and clipping. Run a distortion simulation with the audio files given by the cell array audioFiles. Noise is added to the audio file using noiseFunc and the audio is clipped with clipFunc. The optimization method optMethod which is a method_max. The audio is evaluated by a metric which must be a method_eval.

### Example input specifications:
distortSim(eval_FSF(),max_OptGrid(10),@noise_func1,@clip_mx0p04_s15,fullfile('\directory\Loud_20_Words',{'F1_Loud_Norm_DiffNeigh_VaryFill.wav','F3_Loud_Norm_DiffNeigh_VaryFill.wav','M3_Loud_Norm_DiffNeigh_VaryFill.wav','M4_Loud_Norm_DiffNeigh_VaryFill.wav'}),'tol',1)

## export_data2csv_M4
Reads Volume Adjust .mat data files and creates a CSV. CSV files can be used for quick analysis in multiple software packages.

### Example input specifications:
export_data2csv_M4('Dat_Dir','\directory\Analog Direct','Dat_Name','capture_M4-Analog-Direct_01-Dec-2020_07-09-01')

# TECHNICAL SUPPORT
For more information or assistance on optimal transmit volume measurements please contact:
Chelsea Greene\
Public Safety Communications Research Division\
National Institute of Standards and Technology\
325 Broadway\
Boulder, CO 80305\
303-497-6852; Chelsea.Greene@nist.gov

# Disclaimer
**Much of the included software was developed by NIST employees, for that software the following disclaimer applies:**

This software was developed by employees of the National Institute of Standards and Technology (NIST), an agency of the Federal Government. Pursuant to title 17 United States Code Section 105, works of NIST employees are not subject to copyright protection in the United States and are considered to be in the public domain. Permission to freely use, copy, modify, and distribute this software and its documentation without fee is hereby granted, provided that this notice and disclaimer of warranty appears in all copies.

THE SOFTWARE IS PROVIDED 'AS IS' WITHOUT ANY WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, ANY WARRANTY THAT THE SOFTWARE WILL CONFORM TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND FREEDOM FROM INFRINGEMENT, AND ANY WARRANTY THAT THE DOCUMENTATION WILL CONFORM TO THE SOFTWARE, OR ANY WARRANTY THAT THE SOFTWARE WILL BE ERROR FREE. IN NO EVENT SHALL NIST BE LIABLE FOR ANY DAMAGES, INCLUDING, BUT NOT LIMITED TO, DIRECT, INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES, ARISING OUT OF, RESULTING FROM, OR IN ANY WAY CONNECTED WITH THIS SOFTWARE, WHETHER OR NOT BASED UPON WARRANTY, CONTRACT, TORT, OR OTHERWISE, WHETHER OR NOT INJURY WAS SUSTAINED BY PERSONS OR PROPERTY OR OTHERWISE, AND WHETHER OR NOT LOSS WAS SUSTAINED FROM, OR AROSE OUT OF THE RESULTS OF, OR USE OF, THE SOFTWARE OR SERVICES PROVIDED HEREUNDER.

**Some software included was developed by NTIA employees, for that software the following disclaimer applies:**

THE NATIONAL TELECOMMUNICATIONS AND INFORMATION ADMINISTRATION,
INSTITUTE FOR TELECOMMUNICATION SCIENCES ("NTIA/ITS") DOES NOT MAKE
ANY WARRANTY OF ANY KIND, EXPRESS, IMPLIED OR STATUTORY, INCLUDING,
WITHOUT LIMITATION, THE IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR
A PARTICULAR PURPOSE, NON-INFRINGEMENT AND DATA ACCURACY.  THIS SOFTWARE
IS PROVIDED "AS IS."  NTIA/ITS does not warrant or make any
representations regarding the use of the software or the results thereof,
including but not limited to the correctness, accuracy, reliability or
usefulness of the software or the results.

You can use, copy, modify, and redistribute the NTIA/ITS developed
software upon your acceptance of these terms and conditions and upon
your express agreement to provide appropriate acknowledgments of
NTIA's ownership of and development of the software by keeping this
exact text present in any copied or derivative works.

The user of this Software ("Collaborator") agrees to hold the U.S.
Government harmless and indemnifies the U.S. Government for all
liabilities, demands, damages, expenses, and losses arising out of
the use by the Collaborator, or any party acting on its behalf, of
NTIA/ITS' Software, or out of any use, sale, or other disposition by
the Collaborator, or others acting on its behalf, of products made
by the use of NTIA/ITS' Software.


**Audio files included with this software were derived from the MRT Audio Library.**