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
Used to measure ABC-MRT scores across evaluated volume levels.
ABC-MRT16 calculations

## model_gen 
### Example input specifications:

## maxTest 
### Example input specifications:

eval_PESQ (think about this)*
## maxmethod_check 
plots interval values, opt points
### Example input specifications:


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