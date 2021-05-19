import os
import mcvqoe
import unittest
#import numpy as np
import scipy.io.wavfile as wav
from fsf import fsf

class TestEval_FSF(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.audio_dir = os.path.join(os.curdir, 'eval_FSF Test Cases')
    
    #def evaluate_csv(python_csv, matlab_csv, diff_csv):
        
    def test_eval_fsf(self):
        _, tx_data = wav.read(os.path.join(self.audio_dir, 'F3_Loud_Norm_DiffNeigh_VaryFill.wav')) 
        _, rx_data = wav.read(os.path.join(self.audio_dir, 'Rx1_dly_corrected.wav'))
        tx_data = mcvqoe.audio_float(tx_data)
        rx_data = mcvqoe.audio_float(rx_data)
        score = fsf(tx_data, rx_data)
        self.assertEqual(score, 1.036)

if __name__ == '__main__':
    unittest.main()