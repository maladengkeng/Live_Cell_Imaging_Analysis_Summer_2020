%% This programme segements Phase Contrast images using SuperSegger
close all; clc; clear all;

% ~~~~ START EDIT ~~~~
file_name = 'PC1';
% ~~~~ STOP  EDIT ~~~~

%% Set configuration variables
addpath(genpath(pwd))
addpath('./Functions_MATLAB')

configVar = Configure();
cd(configVar.rootPath) 

%% Preprocess
clc; fprintf('Preprocessing ...\n')
PreProcessor(file_name,configVar)

%% Process
clc; fprintf('Processing ...\n')
SuperSeggerSegment(configVar)

%% Load output
clc; fprintf('Loading output ...\n')
[label, outlines, properties] = LoadOutput(configVar);

%% Postprocess
clc; fprintf('Postprocessing ...\n')
[labelNew, outlinesNew] = PostProcessor(configVar,label,file_name);

%% Display segmentation
clc; fprintf('Displaying results ...\n')
DisplaySegmentation(configVar, file_name, outlinesNew, labelNew, outlines, label)

clc; fprintf('Finished!\n')
