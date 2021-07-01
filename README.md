# Summary
The purpose of this software is to find the optimal transmit volume for a push-to-talk (PTT) communications device for a system under test (SUT) using a transmit volume optimization (TVO) tool. TVO  should be performed for every combination of PTT device under test and every audio file used in performing Mission Critical Voice (MCV) quality of experience (QoE) measurements.  

## Obtaining Software
- Code available at:
- Data available at:
- Paper available at:

## Hardware Requirements 
- See **Link to paper and access time paper**

## Software Requirements
- MATLAB R2018a or newer with the following toolboxes:
	- Audio System Toolbox
	- Signal Processing Toolbox

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

## eval_PESQ (think about this)*

## maxmethod_check 
Take in a CSV of project data. Create a model from data. Run it through max_OptGrid, and get information about behavior. Output options include information on mean and standard deviation values of the data; plots of decisions across eval points; plots of the final optimal values with intervals; plots of the groups across eval points.

### Example input specifications:
MaxMethod_Check('Dat_Path', '\\cfs2w.nist.gov\671\Projects\MCV\Volume-test\Volume Impact Project\Fourth Phase Data - Updated CSVs\Analog Direct\Additional Data\capture_M4-extra_31-Dec-2020_10-44-42.csv', 'Tol',1, 'Noise', 0.02)


## volume_sort
pesqwrapper (think about this)
## GroupPlotCheck 

## distortSim *

## export_data2csv_M4

# TECHNICAL SUPPORT
For more information or assistance on optimal volume measurements please contact:
Chelsea Greene
Public Safety Communications Research Division
National Institute of Standards and Technology
325 Broadway
Boulder, CO 80305
303-497-6852; Chelsea.Greene@nist.gov

# Disclaimer