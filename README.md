# Summary
The purpose of this software is to find the optimal transmit volume for a push-to-talk (PTT) communications device performing Mission Critical Voice (MCV) quality of experience (QoE) measurements using a transmit volume optimization (TVO) tool. TVO should be performed for every combination of PTT device under test and every audio file used in performing MCV QoE measurements.  

Additional scripts not mentioned in the README that live in the repository are helper functions utilized in the main scripts listed.

## Obtaining Software
- Code available at: https://github.com/usnistgov/MCV-QOE-TVO
- Data available at: https://doi.org/10.18434/mds2-2432
- Paper available at: https://doi.org/10.6028/NIST.TN.2171

## Obtaining Data 
Data is available at: https://doi.org/10.18434/mds2-2432

## Hardware Requirements 
See the following:
- Optimal Transmit Volume Conditions for Mission Critical Voice Quality of Experience Measurement Systems
  - https://doi.org/10.6028/NIST.TN.2171 
- Mission Critical Voice QoE Access Time Measurement Methods 
  - https://github.com/usnistgov/accessTime
  - https://www.nist.gov/ctl/pscr/mission-critical-voice-qoe-access-time-measurement-methods

**Additional details and information can be found in the paper linked above.**

## Software Requirements
- MATLAB R2019a or newer with the following toolboxes:
	- Audio Toolbox 
	- Signal Processing Toolbox
- R version 3.5.X or newer
    - RStudio (recommended)
	- ggpubr, dplyr, ggplot2, broom, tinytex packages 

# Running TVO 
The software is divided into subfolders for the type of test that is being performed. The main directory contains code needed to run a TVO. For additional setup information please refer to doccumentation in the paper. 

To run the TVO, run the volume_adjust.m script. Speech will be played and recorded using the connected audio device. The data is stored in a subfolder named *OutDir/data/*. 

volume_adjust.m takes in a variety of optional input paramaters. Default input may be used. Advanced users may be interested in specifying some input paraters. Parameters that may be customized include:
- AudioFile: audio file to be used for performing tests.
- Trials: Number of trials to run for each sample volume.
- Volumes: Instead of using the algorithm to determine what volume levels to sample, explicitly set the volume sample points. When this is given no optimal volume is calculated.
- Lim: Sets the volume limits to use for the test in dB. 
- PTTGap: Time to pause after completing one trial and starting the next. This setting may need to change if one is using a SUT with broadband. 
- tol: Tolerance value used to set minimum spacing between evaluated volume levels.

## Example input specifications:
- volume_adjust
- volume_adjust('AudioFile', 'Filepath\My_Test.wav', 'Trials', 80, 'Lim', [-30,-10],'tol',2)
 
There are additional scripts in the main directory. These are used to run the main componenents of the TVO. The folder *private* contains additional helper functions to run this measurement.

# Audio Files
Audio files can be found in the *clips* folder. By default, all four of these audio files are used. The csv files with cutpoints, as well as the test wav files, are included. 


# TECHNICAL SUPPORT
For more information or assistance on optimal transmit volume measurements please contact:

Chelsea Greene\
Public Safety Communications Research Division\
National Institute of Standards and Technology\
325 Broadway\
Boulder, CO 80305\
303-497-6852; Chelsea.Greene@nist.gov or PSCR@PSCR.gov

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
