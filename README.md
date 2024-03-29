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



# Running TVO 

## Installing Software
To install the software run
```
pip install mcvqoe-tvo
```

Alternatively, one could clone this repository and run the following from the root of the git repository:
```
pip install .
```

## Running a measurement
The easiest way to use the measurement system is to run the GUI (https://github.com/usnistgov/mcvqoe).

# Audio Files
Audio files can be found in the `mcvqoe/tvo/audio_clips` folder. By default, all four of these audio files are used. The csv files with cutpoints, as well as the test wav files, are included. 


# TECHNICAL SUPPORT
For more information or assistance on access delay measurements please contact:

Public Safety Communications Research Division\
National Institute of Standards and Technology\
325 Broadway\
Boulder, CO 80305\
PSCR@PSCR.gov

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
