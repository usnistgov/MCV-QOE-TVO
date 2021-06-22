# Summary
The purpose of this software is to find the optimal transmit volume for a push-to-talk (PTT) communications device for a system under test (SUT) using a transmit volume optimization (TVO) tool. TVO  should be performed for every combination of PTT device under test and every audio file used in performing Mission Critical Voice (MCV) quality of experience (QoE) measurements.  

# Obtaining Software
- Code available at:
- Data available at:
- Paper available at:

# Hardware Requirements 
- See *Link to paper and access time paper*

# Software Requirements
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

Example input specifications:
- volume_adjust
- volume_adjust('AudioFile', 'Filepath\My_Test.wav', 'Trials', 80, 'Lim', [-30,-10],'tol',2)

# Audio Files
Audio files can be found in the 'clips' folder. By default, all four of these audio files are used. 

# Statistical Analysis


# Additional Tools


# TECHNICAL SUPPORT
For more information or assistance on optimal volume measurements please contact:
Chelsea Greene
Public Safety Communications Research Division
National Institute of Standards and Technology
325 Broadway
Boulder, CO 80305
303-497-6852; Chelsea.Greene@nist.gov

# Disclaimer