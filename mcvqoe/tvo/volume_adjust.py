import csv
import datetime
import mcvqoe.base
import mcvqoe.math
import os
import pkg_resources
import scipy.signal
import signal
import time

import numpy as np

from collections import namedtuple
from fractions import Fraction
from warnings import warn

class measure:
    """
    Class to determine optimal volume for a test setup. A Transmit Volume
    Optimization (TVO) tool.
    
    Attributes
    ----------
    audio_files : list of strings
        List of names of audio files. Paths are relative to audio_path if given.
    audio_path : string
        Path where audio is stored.
    audio_interface : mcvqoe.AudioPlayer or mcvqoe.simulation.QoEsim
        Interface to use to play and record audio on the communication channel
    dev_volume : float
        Volume setting on the device. This tells VolumeAdjust what the output
        volume of the audio device is. This is taken into account when the
        scaling is done for the trials. Default is 0 dB.
    get_post_notes : function or None
        Function called to get notes at the end of the test. Often set to
        mcvqoe-post_test to get notes with a gui popup.
        lambda : mcvqoe.post_test(error_only=True) can be used if notes should
        only be gathered when there is an error
    info : dict
        Dictionary with test info for the log entry
    lim : list of floats
        TLim must be a 2 element list that is increasing. lim sets the volume
        limits to use for the test in dB. lim defaults to [-40.0, 0.0].
    no_log : tuple of strings
        Static property that is a tuple of property names that will not be added
        to the 'Arguments' field in the log. This should not be modified in most
        cases.
    opt_method : method_max
        A method_max class to use to determine which points to evalute next and,
        at the end, return a value.
    outdir : string, default=''
        Base directory where data is stored
    ptt_gap : float
        Time to pause, in seconds, between one trial and the next. Defaults to
        3.1 s.
    scaling : boolean
        Scale the clip volume to simulate adjusting the device volume to the 
        desired level. If this is False then the user will be prompted every time
        the volume needs to be changed. Defaults to True
    smax : int
        Maximum number of sample volumes to use. Default is 30.
    tol : float
        Tolerance value. Used to set 'Opt.tol'.
    trials : int
        Number of trials to run for each sample volume.
    volumes : list of floats
        Instead of using the algorithm to determine what volumes to sample,
        explicitly set the volume sample points. When this is given no
        optimal volume is calculated. Default is an empty list.
        
    Methods
    -------
    
    Examples
    --------
    """
    
    data_fields = {
        "Timestamp" : str,
        "Filename" : str,
        "Volume" : float,
        "FSF" : float,
        "m2e_latency" : float,
        "Channels" : mcvqoe.base.parse_audio_channels, 
    }
    
    def __init__(self, **kwargs):
        
        self.audio_files = []
        self.audio_path = ""
        self.audio_interface = None
        self.dev_volume = 0.0
        self.get_post_notes = None
        self.info = {'Test Type': 'default', 'Pre Test Notes': ''}
        self.lim = [-40.0, 0.0]
        self.no_log = ('test', 'ri')
        # TODO figure out if I need a class for this one
        self.opt_method = None
        self.outdir = ""
        self.ptt_gap = 3.1
        self.ptt_wait = 0.68
        self.ri = None
        self.scaling = True
        self.smax = 30
        # TODO: Add these to be functional
        self.save_audio = True
        self.save_tx_audio = True
        # TODO figure how tol ties into everything
        self.tol = 0.0
        self.ptt_rep = 40
        self.volumes = []
        
        for k, v in kwargs.items():
            if hasattr(self, k):
                setattr(self, k, v)
            else:
                raise TypeError(f"{k} is not a valid keyword argument")
    
    def csv_header_fmt(self):
        """
        generate header and format for .csv files.
        
        This generates a header for .csv files along with a format (that can be
        used with str.format()) to generate each row in the .csv.
        
        Parameters
        ----------
        
        Returns
        -------
        hdr : string
            csv header string
        fmt : string
            format string for data lines for the .csv file
        """
        hdr=','.join(self.data_fields.keys())+'\n'
        fmt='{'+'},{'.join(self.data_fields.keys())+'}\n'
        
        return (hdr, fmt)

    
    def setup_grid(self):
        """Populate array of x-values to evaluate at"""
        
        # Check if this is the first grid
        if self.eval_step == 0:
            # Generate a linear grid over the interval with the given number of points
            self.grid = np.linspace(self.lim[0], self.lim[1], self.points)
            # Get spacing from grid
            self.spacing = np.mean(np.diff(self.grid))
        else:
            # Set new spacing
            self.spacing = np.true_divide(self.spacing, 2)
            # Check if we have an initial grid
            if self.win_found:
                # Sample points around edge points
                ng = np.array([self.lim[0]-self.spacing, self.lim[0]+self.spacing,
                               self.lim[1]-self.spacing, self.lim[1]+self.spacing])
            else:
                # Generate new grid on interval with new spacing
                ng = np.arange(self.lim[0], self.lim[1], self.spacing)
            
            # Preallocate
            rpt = np.zeros((len(ng)), dtype='bool')
            # Find repeat points
            for k in range(len(ng)):
                # Consider 2 points the smae if they are closer than 1
                # 100th of the spacing. We're getting rounding errors otherwise
                rpt[k] = np.any(np.abs(ng[k]-self.x_values) < np.true_divide(self.spacing, 100))
            
            # Set new grid, skipping repeats
            # TODO does this work?
            self.grid = np.ma.masked_array(ng, mask=rpt)
        
        self.start_step = self.eval_step
        
    def get_eval(self):
        """Return the next x-value to evaluate at"""
        
        # Check for empty grid
        if self.grid:
            # TODO Do I need to add 1 here like MATLAB?
            return self.grid(self.eval_step-self.start_step)
        else:
            return np.nan
    
    def get_next(self, eval_x, y_vals):
        """Get the next x value to evaluate at based on new data"""
        
        # Set to next step
        self.eval_step = self.eval_step + 1
        # Save data with dither noise
        self.y_values[self.eval_step] = y_vals + np.random.normal(0, 0.5, len(y_vals))
        self.x_values[self.eval_step] = eval_x
        
        # Check if we need a new grid
        if((self.start_step+len(self.grid)) == self.eval_step):
            
            for k in range(self.start_step, self.eval_step):
                if not (self.groups):
                    self.groups.append(k)
                else:
                    found = 0
                    for kk in range(0, len(self.groups)):
                        if (mcvqoe.math.approx_permutation_test(self.y_values[k], self.y_values[self.groups[kk]])):
                            self.groups[kk] = [self.groups[kk], k]
                            # Found! Done
                            found = 1
                            break
                    
                    if not found:
                        # Not found, add new group
                        self.groups.append(k)
                        
            # Get group length
            group_size = [len(i) for i in self.groups]
            mean_y = np.zeros(len(group_size))
            
            for k in range(len(self.groups)):
                # Compute the mean of y-values
                mean_y[k] = np.mean(self.y_values[self.groups[k]])
                
            g_score = np.multiply(mean_y, group_size)
            
            # Check max group size
            if np.amax(group_size) > 1:
                
                # Find which score is max
                self.chosen_group = np.argmax(g_score)
                
                # Get sorted x-values
                group_x = np.sort(self.x_values[self.groups[self.chosen_group]])
                
                # We have a group with multiple points, window found
                self.win_found = True
                # Set current interval from group
                self.lim[0] = group_x[0]
                self.lim[1] = group_x[-1]
                
            # New grid
            self.setup_grid()
            # Check grid size
            done = self.spacing < self.tol
            
        else:
            done = False
            
        # Get next eval point
        x_val = self.get_eval()
        
        return x_val, done
    
    def get_opt(self):
        """Return the optimal point
        
        The optimal point is defined as the point 4/5 away from the lower part of 
        the current interval of interest
        """
        
        # Get group length
        group_size = [len(i) for i in self.groups]
        # Check that we have groups and not individuals
        if np.amax(group_size) > 1:
            print(f"Optimal interval: [{self.lim[0]}, {self.lim[1]}]")
            # Set the opt value to be 4/5 of the way in the interval
            int_length = np.absolute(self.lim[0]-self.lim[1])
            opt = self.lim[0] + (int_length*(4/5))
            return opt
        else:
            warn(f"No groups formed. Optimal interval not found.")
            return np.nan
    
    def opt_vol_pnt(self, new_eval=False):
        
        # If new evaluation, reset internal values
        if new_eval:
            self.points = 10
            self.eval_step = 0
            self.win_found = False
            self.chosen_group = np.nan
            self.y_values = []
            self.x_values = []
            self.groups = []
            
    def load_audio(self):
        """
        load audio files for use in test.
        
        this loads audio from self.audio_files and stores values in self.y, and
        self.cutpoints. In most cases run() will call this automatically but,
        it can be called in the case that self.audio_files is changed after
        run() is called.

        Parameters
        ----------

        Returns
        -------

        Raises
        ------
        ValueError
            If self.audio_files is empty
        RuntimeError
            If clip fs is not 48 kHz
        """

        # If we are not using all files, check that audio files is not empty
        if not self.audio_files:
            raise ValueError("Expected self.audio_files to not be empty")
        
        # Check if we have an audio interface (running actual test)
        if self.audio_interface:
            # Get sample rate, we'll use this later
            fs_test = self.audio_interface.sample_rate
        else:
            # Set to none for now, we'll get this from files
            fs_test = None
        
        # List for input speech
        self.y = []
        # List for cutpoints
        self.cutpoints = []
        
        for f in self.audio_files:
            # Make full path from relative paths
            f_full = os.path.join(self.audio_path, f)
            # Load audio
            fs_file, audio_dat = mcvqoe.base.audio_read(f_full)
            # Check fs
            if fs_file != fs_test:
                # Check if we have a sample rate
                if not fs_test:
                    # No, set from file
                    fs_test = fs_file
                    # Set audio
                    audio = audio_dat
                else:
                    # Yes, resample to desired rate
                    rs_factor = Fraction(fs_test / fs_file)
                    audio = scipy.signal.resample_poly(
                        audio_dat, rs_factor.numerator, rs_factor.denominator
                    )
            else:
                # Set audio
                audio = audio_dat
                
            # Append audio to list
            self.y.append(audio)
            # Strip extension from file
            fne, _ = os.path.splitext(f_full)
            # Add .csv extension
            fcsv = fne + '.csv'
            # Load cutpoints
            cp = mcvqoe.base.load_cp(fcsv)
            
            # Add cutpoints to array
            self.cutpoints.append(cp)
            
        # Check if we have an audio interface (running actual test)
        if not self.audio_interface:
            # Create a named tuple to hold sample rate
            FakeAi = namedtuple('FakeAi', 'sample_rate')
            # Create a fake one
            self.audio_interface = FakeAi(sample_rate = fs_test)
            
    def run(self):
        
        """Run a volume adjust test"""
        
        #------------------[List Vars to Save in File]------------------
        
        save_vars = ('p', 'git_status', 'y', 'dev_name', 'test_dat',
                     'fs', 'opt', 'vol_scl_en', 'clipi', 'cutpoints',
                     'method')
        
        #--------------[Check for Correct Audio Channels]---------------
        
        if('tx_voice' not in self.audio_interface.playback_chans.keys()):
            raise ValueError('self.audio_interface must be set up to play tx_voice') 
        if('rx_voice' not in self.audio_interface.rec_chans.keys()):
            raise ValueError('self.audio_interface must be set up to record rx_voice')

        #---------------------[Get Test Start Time]---------------------

        self.info['Tstart'] = datetime.datetime.now()
        dtn = self.info['Tstart'].strftime('%d-%b-%Y_%H-%M-%S')

        #----------------------[Fill Log Entries]-----------------------
        
        # Set test name
        self.info['test'] = 'Volume Adjust'
        # Fill in standard stuff
        self.info.update(mcvqoe.base.write_log.fill_log(self))

        #--------------[Initialize Folders and Filenames]---------------
        
        # Generate data dir names
        data_dir = os.path.join(self.outdir, 'data')
        wav_data_dir = os.path.join(data_dir, 'wav')
        csv_data_dir = os.path.join(data_dir, 'csv')
        
        # Create data directories
        os.makedirs(wav_data_dir, exist_ok=True)
        os.makedirs(csv_data_dir, exist_ok=True)
        
        # Generate base filename to use for all files
        base_filename = f"capture_{self.info['Test Type']}_{dtn}"
        
        # Generate and create test dir names
        wavdir = os.path.join(wav_data_dir, base_filename)
        os.makedirs(wavdir, exist_ok=True)
        
        # Get names of audio clips without path or extension
        clip_names = [os.path.basename(os.path.splitext(a)[0]) for a in self.audio_files]
        
        # Generate csv filenames and add path
        file = f"{base_filename}.csv"
        tmp_f = f"{base_filename}_TEMP.csv"
        file = os.path.join(csv_data_dir, file)
        tmp_f = os.path.join(csv_data_dir, tmp_f)
        self.data_filename = file
        temp_data_filename = tmp_f
            
        # Generate filename for bad csv data
        bad_name = f"{base_filename}_BAD.csv"
        bad_name = os.path.join(csv_data_dir, bad_name)
        
        #--------------------[Generate CSV Header]----------------------
        
        header, dat_format = self.csv_header_fmt()
        
        #-----------------[Load Audio Files if Needed]------------------
        
        if not hasattr(self, "y"):
            self.load_audio()
        
        #-------------------[Get Max Number of Loops]-------------------
        
        if self.volumes:
            self.smax = len(self.volumes)
            
        #-----------------------[write log entry]-----------------------
        
        mcvqoe.base.pre(info=self.info, outdir=self.outdir)
        
        #-----------------[Create Arrays & Variables]-------------------
        
        # Arrays
        volume = []
        eval_vals = []
        
        # Used to cycle between audiofiles
        clipi = np.mod(range(self.ptt_rep), len(self.y))
        
        # Variables
        opt = np.nan
        trial_count = 0
        
        # Setup for Optimization Method
        if self.volumes:
            volume = self.volumes
        else:
            max_dat = []
        #--------------------[Notify User of Start]---------------------
        
        
        # Only print assumed device volume if scaling is enabled
        if self.scaling:
            # Print assumed device volume for confirmation
            print(f"\nAssuming device volume of {self.dev_volume} dB\n")
        
        # Turn on LED
        self.ri.led(1, True)
        
        try:
            
            #----------------------[Write CSV Header]-----------------------
            
            with open(temp_data_filename, "wt") as f:
                f.write(header)
            
            #--------------------[Volume Selection Loop]--------------------
            
            for k in range(self.smax):
                
                #------------------[Initialize CSV Dictionary]------------------
                    
                csv_data = {}
                
                #-----------------[Arrays for Data Collection]------------------
                
                # Holds FSF values
                eval_dat = [0.0 for i in range(self.ptt_rep)]
                
                #------------------[Compute Next Sample Point]------------------
                
                # Check if volumes were given
                if not self.volumes:
                    if k == 0:
                        # Initial run initialization
                        volume.append(self.opt_vol_pnt(new_eval=True))
                        # Can't be done before we start
                        done = False
                        
                    else:
                        # Process data and get next point
                        new_vol, done = self.get_next(volume[k-1], eval_dat[k-1])
                        volume.append(new_vol)
                        
                    # TODO Check for convergence
                    if(done):
                        print(f"Checked for convergence")
                        
                #------------------------[Skip Repeats]-------------------------
                
                # Check if volumes were given
                if not self.volumes:
                    # Check to see if we are evaluationg a value that has been done before
                    abs = np.absolute([((volume[k] - vol) < (self.tol/1000)) for vol in volume[0:k]])
                    idx = np.argwhere(abs)[0]
                    
                    # Check if value was found
                    if idx.size > 0:
                        # If we have a value, extract it from NumPy array
                        id = idx[0]
                        print(f"\nRepeating volume of {volume[k]}, using volume from run {id}"+
                              f" (vol = {volume[id]} skipping to next iteration...\n")
                        # Copy old values
                        eval_vals[k] = eval_vals[id]
                        eval_dat[k] = eval_dat[id]
                        # Skip to next iteration
                        continue
                    
                #------------------------[Change Volume]------------------------
                # Volume is changed by scaling the waveform or prompting the user
                # to change it in the audio device configuration
                
                # Check if we are scaling or using device volume
                if self.scaling:
                    # Print message with volume level
                    print(f"\nScaling volume to {volume[k]} dB\n")
                    
                    # Add volume to dictionary
                    csv_data['Volume'] = volume[k]
                    
                    # Scale audio to volume level
                    y_scl = []
                    for jj in range(len(self.y)):
                        y_scl.append((10**((volume[k]-self.dev_volume)/20)) * self.y[jj])
                
                else:
                    
                    # Turn on other LED because we are waiting
                    self.ri.led(2, True)
                    
                    # Get volume to set device to
                    d_volume = np.around(volume[k])
                    
                    # Add volume to dictionary
                    csv_data['Volume'] = d_volume
                    
                    # TODO: prompt user to set new volume
                    
                    # TODO: Check if value was given
                    
                    # Scale audio volume to make up the difference
                    # Scale audio to volume level
                    y_scl = []
                    for jj in range(len(self.y)):
                        y_scl.append(((10**(volume[k]-d_volume)/20)) * self.y[jj])
                    
                    # Turn off other LED
                    self.ri.led(2, False)
                    
                #----------------------[Measurement Loop]-----------------------
                
                for kk in range(self.ptt_rep):
                    
                    #---------------------[Get Trial Timestamp]---------------------
                    
                    csv_data['Timestamp'] = datetime.datetime.now().strftime("%d-%b-%Y %H:%M:%S")
                    
                    #------------------[Key Radio and Play Audio]-------------------
                    
                    # Push the PTT button
                    self.ri.ptt(True)
                
                    # Pause to let the radio key up
                    time.sleep(self.ptt_wait)
                    
                    # Create audiofile name/path for recording
                    audioname = f"Rx{kk+1}_{self.audiofiles[clipi[kk]]}.wav"
                    
                    # Play and record audio data
                    rec_name = self.audio_interface.play_record(y_scl[clipi[kk]], audioname)
                    
                    # Release the PTT button
                    self.ri.ptt(False)
                    
                    # Pause between runs
                    time.sleep(self.ptt_gap)
                    
                    # Increment trial count
                    trial_count = trial_count + 1
                    
                    #------------------[Check if Pause is Needed]-------------------
                    
                    # TODO do we need this?
                    
                    #----------------[Volume Level Data Processing]-----------------
                
                    # Call fsf method
                    eval_dat[kk], csv_data['m2e_latency'] = mcvqoe.base.fsf(rec_name, self.y[clipi[kk]])
                                                                   
                    #------------------------[Write to CSV]-------------------------
                    
                    # Place info inside Dictionary
                    csv_data['Filename'] = self.audiofiles[clipi[kk]]
                    csv_data['Channels'] = mcvqoe.base.audio_channels_to_string(rec_name)
                    csv_data['FSF'] = eval_dat[kk]
                    
                    # Write to CSV
                    with open(temp_data_filename, "at") as f:
                        f.write(
                            dat_format.format(**csv_data)
                        )
                    
                # Compute mean of FSF values                                          
                eval_vals[k] = np.mean(eval_dat)
                
                # Print mean
                print(f"\nEval method returned {eval_vals[k]}\n")
                
            # Calculate optimal volume
            if not self.volumes:
                opt = self.get_opt()
            else:
                opt = np.nan
                
        finally:
            if self.get_post_notes:
                # Get notes
                info = self.get_post_notes()
            else:
                info = {}
            
            mcvqoe.base.write_log.post(outdir=self.outdir, info=info)
                