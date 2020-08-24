This code takes .tif files (e.g. converted from Nikon Microscopy Format in NIS Elements viewer) and performs cell segmentation using SuperSegger (Wiggins Lab, Washington). 
** Dependancies must be adjusted to ones computer by updating config.m file **

Required installations:
MATLAB (code written using version R2018b - academic licence)
SuperSegger (Wiggins Lab, Washington).

############ Input ############ 

Phase contrast images of cells to be segmented are placed in the 'Input' folder. Multiple files can be uploaded, the desired file to be segmented can be selected in Segmentation_main.m.
(input directory can be changed in ./Functions/Configure.m)

############ Settings ############

Settings can be adjusted in ./Functions/Configure.m
Variables are explained there

############ Process ############

The entire process is run from Segmentation_main.m. Only change the file_name to the name of the file to be segmented and optionally change the settings. The main file calls the following funtions: 

- Preprocessor.m prepares the input images for SuperSegger segmentation by homogenizing the background illumination and applying a bilatteral filter. Output   images are then stored temporarily in 'Output' folder.

- SuperSeggerSegment.m retrieves the perpared images and applies SuperSegger for segmentation only using parameters set in ./Functions/Configure.m.

- LoadOutput.m retrieves and converts the SuperSegger output to extract cell outlines and labels.

- PostProcessor.m performs an extra selection to the SuperSegger output by filtering out cells whose properties of area and length-width ratio do not   correspond to those set in ./Functions/Configure.m.

- DisplaySegmentation.m finally displays the output segmentation.

############ Output ############

Output is stored in a new folder called 'MyFileName_Segmention'

This code was written by Wouter Wesselink working at Nynke Dekker Lab, TU Delft. 
