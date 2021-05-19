import math
import mcvqoe
import numpy as np
from scipy import signal
import warnings

def fsf(tx_data, rx_data, fs=48E3):
    """
    Purpose
    -------
    Frequency slope fit distortion detector using Uniform Bands.
    
    Parameters
    ----------
    tx_data : numpy array
        Transmit audio data.
    rx_data : numpy array
        Received audio data.
    fs : double, optional
        Sample rate. The default is 48E3.
  
    Returns
    -------
    score : double
        FSF score.

    """
    
    _, delay_samples = mcvqoe.ITS_delay_est(rx_data, tx_data, mode='f', fsamp=48000)
    if delay_samples < 0:
        #raise ValueError('Negative delay detected.')
        warnings.warn('Negative delay detected. Setting delay to zero.')
        delay_samples = 0
        
    if len(rx_data) < (len(tx_data) + delay_samples):
        rx_data = rx_data[delay_samples:]
    else:
        rx_data = rx_data[delay_samples:(len(tx_data) + delay_samples)]
    
    tx_slope = calc_slope(tx_data)
    
    rx_slope = calc_slope(rx_data)
        
    score = np.true_divide(rx_slope, tx_slope)
    return score
    
def calc_slope(wav_data):
    """
    Purpose
    -------
    Calculates frequency slope fit for a 
    given audio clip.
    
    Parameters
    ----------
    wav_data : numpy array
        Audio data.
    band_x : bool
        Determines whether or not linear fit x values
        come from band centers (false) or band numbers
        (true).

    Returns
    -------
    slope : double
        Slope of wav_data.

    """
    freq_set = np.array([[200, 450], 
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
    
    fft_len = 2 ** 14
    
    num_bands = len(freq_set)
    
    #TODO: Check if already a column vector (avoid transpose if so)
    wav_data = wav_data.T
    
    #TODO: Explore length of hamming window - see if length of window should be less than length of input wav data 
    win = signal.get_window('hamming', len(wav_data))
    #win_1 = signal.windows.hamming(len(wav_data))
    wav_win = win * wav_data
    freq, pxx = signal.periodogram(wav_win, fs=int(48E3), nfft=fft_len, scaling='spectrum')
    #freq, pxx = signal.periodogram(wav_data, fs=48E3, nfft=fft_len, detrend=False, scaling='spectrum')
     
    band_vals = np.zeros((num_bands))
    
    #TODO: Look into list comprehension 
    for band in range(num_bands):
        mask = np.logical_and((freq >= freq_set[band, 0]), (freq <= freq_set[band, 1]))
        band_vals[band] = 10 * math.log10(np.mean(pxx[mask]))
            
    max_idx = np.argmax(band_vals[0:round(num_bands/2)])
        
    fit_range = np.arange(max_idx, band_vals.shape[0])
        
    x_vals = np.arange(0, num_bands)
    x_vals = x_vals[fit_range]
            
    p = np.polynomial.polynomial.polyfit(x_vals, band_vals[fit_range], 1)
    
    slope = p[0]
    
    return slope
    




