# -*- coding: utf-8 -*-
"""
Created on Wed Dec 15 15:53:47 2021

@author: jkp4
"""

import argparse
import json
import os
import re
import warnings

import plotly.graph_objects as go
import numpy as np
import pandas as pd
import plotly.express as px

import mcvqoe.math


# Main class for evaluating
class evaluate():
    """
    Class to evaluate TVO.

    Parameters
    ----------
    test_names : str or list of str
        File names of TVO tests.

    test_path : str
        Full path to the directory containing the sessions within a test.

    use_reprocess : bool
        Whether or not to use reprocessed data, if it exists.

    Attributes
    ----------
    full_paths : list of str
        Full file paths to the sessions.

    mean : float
        Average of all the TVO data.

    ci : numpy array
        Lower and upper confidence bound on the mean.

    Methods
    -------
    eval()
        Determine the TVO of a test.

    See Also
    --------
        mcvqoe.TVO.measure : 
            Measurement class for generating TVO data.
    """

    def __init__(self,
                 test_name=None,
                 test_path='',
                 use_reprocess=False,
                 json_data=None,
                 **kwargs):
        
        # Check for kwargs
        for k, v in kwargs.items():
            if hasattr(self, k):
                setattr(self, k, v)
            else:
                raise TypeError(f"{k} is not a valid keyword argument")
        if json_data is not None:
            self.test_name, self.optimal, self.data = evaluate.load_json_data(json_data)
        else:
            # If only one test, make a list for iterating
            if isinstance(test_name, list):
                if len(test_name) > 1:
                    raise ValueError(f'Can only process one TVO measurement at a time, {len(test_name)} passed.')
                else:
                    test_name = test_name[0]
            # split name to get path and name
            # if it's just a name all goes into name
            dat_path, name = os.path.split(test_name)
            
            # If no extension given use csv
            fname, fext = os.path.splitext(test_name)
            self.test_name = os.path.basename(fname)
            # check if a path was given to a .csv file
            if not dat_path and not fext == '.csv':
                # generate using test_path
                dat_path = os.path.join(test_path, 'csv')
                dat_file = os.path.join(dat_path, fname +'.csv')
            else:
                dat_file = test_name
    
            full_path = dat_file
    
            self.optimal, self.data = evaluate.load_data(full_path)
        
        

    @staticmethod    
    def load_data(filepath):
        """
        Load data in filepath and return optimum and raw data.
        
        Parameters
        ----------
        filepath : str
            Path to TVO data
            
        Returns
        -------
        optimum : pd.DataFrame
            Data frame containing Optimum (dB), optimum interval lower bound 
            (dB), and optimum interval upper bound (dB).
        data : pd.DataFrame
            Data frame containing volumes and FSF scores from TVO measurement.
        """
        # Load optimum settings
        optimum = pd.read_csv(filepath, nrows=1)
        
        # Load data
        data = pd.read_csv(filepath, skiprows=2)
        # Extract test name
        _, tname = os.path.split(filepath)
        name, ext = os.path.splitext(tname)
        # Store testname
        data['name'] = name
        
        return optimum, data
        
    @staticmethod
    def load_json_data(json_data):
        if isinstance(json_data, str):
            json_data = json.loads(json_data)
        # Extract data, cps, and test_info from json_data
        data = pd.read_json(json_data['measurement'])
        optimum = pd.read_json(json_data['optimal'])
        
        filename = set(json_data['test_info'].keys())
        
        return filename, optimum, data
        
    def to_json(self, filename=None):
        """
        Create json representation of TVO data

        Parameters
        ----------
        filename : str, optional
            If given save to json file. Otherwise returns json string. The default is None.

        Returns
        -------
        None.

        """
        
        test_info = {self.test_name: None}
        out_json = {
            'measurement': self.data.to_json(),
            'optimal': self.optimal.to_json(),
            'test_info': test_info,
                }
        
        # Final json representation of all data
        final_json = json.dumps(out_json)
        if filename is not None:
            with open(filename, 'w') as f:
                json.dump(out_json, f)
        
        return final_json
        
    
    def plot(self, talkers=None, x=None,
             title='Scatter plot of intelligibility scores'):
        df = self.data
        
        # Filter by talkers if given
        # Filter by talkers if given
        if talkers is not None:
            df_filt = pd.DataFrame()
            if isinstance(talkers, str):
                talkers = [talkers]
            for talker in talkers:
                df_filt = df_filt.append(df[df['Filename'] == talker])
            df = df_filt
            

        fig = px.scatter(df, x=x, y='FSF',
                         color='Filename',
                          title=title,
                          )
        if x == 'Volume':
            vol_means = df.groupby('Volume', as_index=False)['FSF'].mean()
            fig.add_trace(
                go.Scatter(x=vol_means['Volume'],
                           y=vol_means['FSF'],
                           name='Average FSF',
                           )
                )
            delta = 0.1
            dmax = df['FSF'].values.max() + delta
            dmin = df['FSF'].values.min() - delta
            
            line_types = ['dash', 'dot', 'dot']
            for key, ddash in zip(self.optimal.columns, line_types):
                fig.add_trace(
                    go.Scatter(
                        x=[self.optimal.loc[0, key], self.optimal.loc[0, key]],
                        y=[dmin, dmax],
                        mode='lines',
                        line=dict(color='black', width=3, dash=ddash),
                        name=key,
                        )
                    )

        return fig


# Main definition
def main():
    """
    Evaluate TVO with command line arguments.

    Returns
    -------
    None.

    """
    # Set up argument parser
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('test_names',
                        type=str,
                        nargs="+",
                        action="extend",
                        help=("Test names (same as name of folder for wav"
                              "files)"))
    parser.add_argument('-p', '--test-path',
                        default='',
                        type=str,
                        help=("Path where test data is stored. Must contain"
                              "wav and csv directories."))
    parser.add_argument('-n', '--no-reprocess',
                        default=True,
                        action="store_false",
                        help="Do not use reprocessed data if it exists.")

    
    args = parser.parse_args()
    t = evaluate(args.test_names, test_path=args.test_path,
                 use_reprocess=args.no_reprocess)

    res = t.eval()

    print(res)

    return(res)


if __name__ == "__main__":
    main()
