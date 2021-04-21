import math
import matplotlib.pyplot as plt
import numpy as np
from scipy import signal

class eval_FSF:
    """
    Purpose
    -------
    eval_FSF is a frequency slope fit distortion detector that uses a linear fit of the power in certain frequency bands to measure distortion.
        eval_FSF()
            Creates a frequency slope fit detector using AI bands.
        eval_FSF('Mel')
            Same as above but uses bands from the Mel scale.    
        eval_FSF(band_matrix)
            Same as above but usees bands given in the two column matrix, band_matrix.
    
    Attributes
    ----------
    name : str
        Method name.
    Freq_Set : numpy array
        Frequency bands to use.
    FFT_len : int
        Length of FFT for band power measurments.
    bandX : bool
        Uses band numbers for x values in linear fit.
    
    Methods
    -------
    process(rec, y, clipi) 
        Processes recordings to obtain a distortion estimation.
    slopeCalc(dat)
        Calculates the slope of a given recording.
    filterPlot()
        Plots filter band edges.
    
    """
    
    FFT_len = 2 ** 14
    bandX = True

    def __init__(self, bands='AI'):
        """
        Purpose
        -------
        Constructor for eval_FSF class
        
        Parameters
        ----------
        band : str or numpy array
        
        """
       
        #Check for AI bands
        if bands == 'AI':
            self.Freq_Set = self.AI_bands()
        #Check for Mel bands
        elif bands == 'Mel':
            self.Freq_Set = self.Mel_bands()
        #Check for custom ((numeric bands))
        elif isinstance(bands, np.ndarray): #find a way to check the dtype
            self.Freq_Set = bands
        #Else throw error
        else:
            raise ValueError("Expected either strings 'AI' or 'Mel' or two column numpy array of type double")
            
    def process(self, rec, y, clipi):
        """
        Purpose
        -------
        Calculates a harmonic distortion score from a set of recordings.

        Parameters
        ----------
        rec : list of numpy arrays
            Set of recordings.
        y : list of numpy arrays
            Playback waveforms.
        clipi : numpy array
            Playback waveform index for each recording.

        Returns
        -------
        score : numpy array
            Harmonic distortion score.

        """
        y_slope = np.zeros(sorted(y.shape))
        y_intercept = np.zeros(sorted(y.shape))
        
        for k in range(y.shape[1]):
            y_slope[k], y_intercept[k] = self.slope_calc(y[k])
        
        slope = np.zeros(sorted(clipi.shape))
        intercept = np.zeros(sorted(clipi.shape))
        
        for k in range(rec.shape[1]):
            slope[k], intercept[k] = self.slope_calc(rec[k])
            
        score = np.true_divide(slope, y_slope[clipi])
        
        return score
         
    def slope_calc(self, dat):
        """
        Purpose
        -------
        Calculates the frequency slope fit for a given recording.
        Performs a linear fit of power in a given band.

        Parameters
        ----------
        dat : numpy array
            Playback waveform or recording.

        Returns
        -------
        slope : double
            Slope from linear fit.
        intercept : double
            Intercept from linear fit.

        """
        num_bands = self.Freq_Set.shape[0]
        
        dat = dat.reshape(dat.size, 1)
        
        win = signal.windows.hamming(dat.shape[1])
        freq, pxx = signal.periodogram(dat, fs=48E3, window=win, nfft=self.FFT_len, scaling='spectrum')
        
        band_vals = np.zeros((num_bands, 1))
        
        for band in range(num_bands):
            mask = np.logical_and((freq >= self.Freq_Set[band, 0]), (freq <= self.Freq_Set[band, 1]))
            band_vals[band] = 10 * math.log10(np.mean(pxx[mask]))
            
        max_idx = np.argmax(band_vals[0:round(num_bands/2)])
        
        fit_range = np.arange(max_idx, band_vals.shape[0])
        
        if self.bandX:
            x_vals = np.arange(1, num_bands)
            x_vals = x_vals[fit_range]
            
        else:
            band_center = np.mean(self.Freq_Set, axis=1)
            x_vals = 10 * math.log10(band_center[fit_range])
            
        p = np.polynomial.polynomial.polyfit(x_vals, band_vals[fit_range], 1)
       
        slope =  p[1]
        intercept = p[0]
        
        return slope, intercept
    
    #def filter_plot(self):
     #   num_bands = self.Freq_Set.shape[0]
      #  fig, ax = plt.subplots()
        
    def AI_bands(): 
        """
        Purpose
        -------
        Generates AI bands.

        Returns
        -------
        bands : numpy array
            AI bands.

        """
        bands = np.array([[200, 450],
                          [400, 650],
                          [600, 850],
                          [800, 1050],
                          [1000, 1250],
                          [1200, 1450],
                          [1400, 1650],
                          [1600, 1850],
                          [1800, 2050],
                          [2000, 2250],
                          [2200, 2450],
                          [2400, 2650],
                          [2600, 2850],
                          [2800, 3050],
                          [3000, 3250]])
        return bands
    
    def Mel_bands():
        """
        Purpose
        -------
        Generates Mel bands.

        Returns
        -------
        bands : numpy array
            Mel bands.

        """
        bands = np.array([[267, 400],
                          [333, 467], 
                          [400, 533],
                          [467, 600],
                          [533, 667],
                          [600, 733],
                          [667, 800],
                          [733, 867],
                          [800, 933],
                          [867, 999],
                          [933, 1071],
                          [999, 1147],
                          [1071, 1229],
                          [1147, 1316],
                          [1229, 1410],
                          [1316, 1510],
                          [1410, 1618],
                          [1510, 1733],
                          [1618, 1856],
                          [1733, 1988],
                          [1856, 2130],
                          [1988, 2281], 
                          [2130, 2444],
                          [2281, 2618],
                          [2444, 2804],
                          [2618, 3004],
                          [2804, 3217]])
        return bands
