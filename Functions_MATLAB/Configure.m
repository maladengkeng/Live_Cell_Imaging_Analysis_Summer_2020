function [configVar] = Configure()

% Set directory parameters
configVar.rootPath = 'M:\tnw\bn\nd\Shared\Wouter\photobleaching\GitHub\Cell_Segmentation';
configVar.pathToData = '.\Input';
configVar.pathToOutput = '.\Output';

% Set experimental parameters
configVar.pixelSize = 0.13; % um\px
configVar.ssConst = '60XEcFull'; % Cell and medium type, see below

% Set postprocessing bounds
configVar.areaBounds = [1, 4]; % Min and Max area of cells in um^2
configVar.lengthWidthRatioBounds = [1.5, 8]; % Ratio between minor and major axis in cells
configVar.circularityBounds = [0.2, 0.7]; % Computed as area^2 / perimeter^2

% SuperSegger parameters, see SuperSegger documentation
configVar.channels = {'PC' 'F'};
configVar.num_xy = 1;
configVar.numSpots = 4;

%%%%%%%%%%%%%%%%%%%% Cell and medium types %%%%%%%%%%%%%%%%%%%%

%   100XEc : Trained on E.coli, 60nm/pix .
%   100XPa : Trained on P.aeruginosa, 60nm/pix.
%   60XEcAB1157 : Trained on E.coli AB1157 on M9 pads, 100nm/pix.
%   60XEcM9 : Trained on E.coli on M9 pads, 100nm/pix.
%   60XEc : Trained on E.coli on LB and M9 pads, 100nm/pix.
%   60XEcLB : Trained on E.coli on LB pads, 100nm/pix.
%   60XBay : Trained on A.baylyi on LB pads, 100nm/pix.
%   60XPa : Trained on P.aeruginosa, 100nm/pix.
%   60XCaulob : Trained on snapshots of C.crescentus, 130 nm/pixel.
end