# Live Cell Imaging Analysis Pipeline
This repository contains two out of five steps for the Live Cell Imaging analysis. Other steps are perfomed in Fiji or NIS Elements viewer or are not yet developed. The pipeline takes in phase contrast and fluorescence images in .nd2  and outputs step fitted intensity traces for individual foci. 

This pipeline contains code written by Filip Asscher, Edo van Veen and  Wouter Wesselink int the Nynke Dekker Lab, TU Delft. 
##
_**Pipeline**_
The pipeline contains the following steps, see also _/Documentation/Pipeline_blueprint_ for a schematic overview:

 1. Convert phase contrast and fluorescence images from .nd2 to .tif format using Nikon Microscopy Format in NIS Elements viewer _(free software)_
 2. Track spots using TrackMate through Fiji, see _Documentation/TrackMate_
 3. Fit steps to TrackMate output using Step_fitting_main.py, see section 2 in this README.md.
 4. Segment the image to detect individual cells using Segmentation_main.m, see section 1 in this README.MD.
 5. In the future, an extra step should be added that combines the output of step 3 and 4 to yield all intensity trails within a certain cell.
##
_**Required installations:**_
 - MATLAB (code written using version R2018b - academic licence)
 - SuperSegger (Wiggins Lab, Washington)
 - Python (3.8 and suitable IDE, e.g. PyCharm, required packages listed in Section 2 below)
 - Fiji (Fiji Is Just ImageJ)
 - NIS Elements Viewer

## 1. Cell Segmentation
This programme uses the SuperSegger by Wiggins Lab.  
***Goal:***  
Read in tiff images and segment all individual cells so that the output segmentation can be used in follow-up analysis.

***Input***

Phase contrast images of cells to be segmented are placed in the 'Input' folder. Multiple files can be uploaded, the desired file to be segmented can be selected in Segmentation_main.m.
(input directory can be changed in ./Functions/Configure.m)

***Settings*** 

Settings can be adjusted in ./Functions/Configure.m
Variables are explained there

***Process*** 

The entire process is run from Segmentation_main.m. Only change the file_name to the name of the file to be segmented and optionally change the settings. The main file calls the following funtions: 

- Preprocessor.m prepares the input images for SuperSegger segmentation by homogenizing the background illumination and applying a bilatteral filter. Output   images are then stored temporarily in 'Output' folder.

- SuperSeggerSegment.m retrieves the perpared images and applies SuperSegger for segmentation only using parameters set in ./Functions/Configure.m.

- LoadOutput.m retrieves and converts the SuperSegger output to extract cell outlines and labels.

- PostProcessor.m performs an extra selection to the SuperSegger output by filtering out cells whose properties of area and length-width ratio do not correspond to those set in ./Functions/Configure.m.

- DisplaySegmentation.m finally displays the output segmentation.

***Output*** 

Output is stored in a new folder called 'MyFileName_Segmentation'

## 2. Step Fitting
This programme uses the step fitting and xml table parsing code written by Edo van Veen.  

***Goal:***  
Read in TrackMate output as fluorophore intensity traces and fit stepping function to these.  
  
***Input:***  
Folder in which TrackMate's output .xml files are stored.  
  
***Settings:***  
Enter fitting and optics parameters in Begin-End-Edit box below. Also enter the trace number you want to analyse.  
The trace with number 1 has the most data points, number 2 has fewer and so on.  
  
***Process:***  
The entire process is run from Step_fitting_main.py. Only change the variables listed above and possibly the root directory.  
After setting the variables, click run. The first time you run the code on a new dataset it takes quite long (~5 min) since  
the TrackMate output needs to be parsed to a new dataframe. From the second time onwards, this dataframe is recycled and it  
should be faster. The output figures are shown in the 'Plots' window.  
  
***Output:***  
Output is given as three figures:  

 1. A graph of the selected intensity trail with steps fitted. The number of fitted steps + 1 (since the step that causes the detection to end is not counted) is displayed in the title of the figure. 
 2. A histogram showing the distribution of all fitted numbers of steps. 
 3. A histogram showing the distribution of all fitted step sizes.

  
***Required Packages:***  
- numpy  
- matplotlib.pyplot  
- pandas  
- os  
- sys  
- sklearn.tree  
- scikit-learn

