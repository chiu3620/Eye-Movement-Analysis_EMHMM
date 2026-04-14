# EMHMM Eye-Tracking Data Analysis

This repository contains MATLAB scripts for processing and analyzing eye-tracking fixation data using Eye Movement analysis with Hidden Markov Models (EMHMM). 

The primary script (`forloop.m`) processes multiple datasets in batch mode. It models individual gaze behaviors using Variational Bayesian HMMs (VB-HMM) and then clusters these behaviors into distinct groups using Hierarchical Expectation Maximization (HEM) to identify common viewing patterns.

## Features

* **Batch Processing:** Automatically iterates through multiple Excel files containing eye-tracking fixation data.
* **Coordinate Normalization:** Converts fixation coordinates from a center-based origin to a top-left-based origin to align with image coordinate systems.
* **VB-HMM Learning:** Trains individual Hidden Markov Models for each subject based on Regions of Interest (ROIs).
* **HEM Clustering:** Clusters individual models into generalized group models (evaluating both 1-group and 2-group solutions).
* **Statistical Analysis:** Generates the top-5 most probable ROI sequences and runs t-tests between identified clusters.
* **Automated Output:** * Saves visual plots of the clustered HMMs as PNG files.
    * Outputs parameter data (priors, transitions, and subject groupings) into consolidated Excel files.
    * Saves command window logs (`.txt`) for reference.

## Prerequisites

* MATLAB (R2018a or newer recommended).
* [EMHMM Toolbox](http://visal.cs.cityu.edu.hk/research/emhmm/) added to the MATLAB path.
* Input data formatted as Excel spreadsheets inside a `data/` directory.
* A background reference image (`Neutral.jpg`) placed in the root directory or updated to the correct path in the script.

## Usage

1. Clone or download this repository.
2. Ensure the `emhmm-toolbox` is located in the same directory as the script.
3. Place your eye-tracking `.xlsx` files in the `data/` folder.
4. Run the script `main.m` in MATLAB.

Results will be automatically generated in directories separated by the maximum number of hidden states (`K=3`, `K=4`, `K=5`).

## Citation

If you use this code or the underlying EMHMM toolbox in your research, please cite the following paper as appropriate:
> **Understanding eye movements in face recognition using hidden Markov models.**
> Tim Chuk, Antoni B. Chan, and Janet H. Hsiao
> *Journal of Vision*, 14(11):8, Sep 2014.