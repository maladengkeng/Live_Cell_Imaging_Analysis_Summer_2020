function [labelNew, outlinesNew] = PostProcessor(configVar,label,file_name)

% Load selection parameters
areaBounds = configVar.areaBounds ./ configVar.pixelSize.^2;
lengthWidthRatioBounds = configVar.lengthWidthRatioBounds;

% Load detected parameters
area = cell2mat(struct2cell(regionprops(label,'Area')));
majorAxisLength = cell2mat(struct2cell(regionprops(label,'MajorAxisLength')));
minorAxisLength = cell2mat(struct2cell(regionprops(label,'MinorAxisLength')));
lengthWidthRatio = majorAxisLength./minorAxisLength;

% Select cells agreeing with bounds
areaOkay = (area < areaBounds(2)) & (area > areaBounds(1));
ratioOkay = (lengthWidthRatio < lengthWidthRatioBounds(2)) & ...
    (lengthWidthRatio > lengthWidthRatioBounds(1));

% Generate new labels and outlines
okay = find(areaOkay .* ratioOkay);
okayInd = zeros(size( label));
for ii = 1:length(okay)
    okayIndTemp = (label == okay(ii));
    okayInd = okayInd + okayIndTemp;
end

% Save new labels and outlines
labelNew = label;
labelNew(okayInd == 0) = 0;
outlinesNew = zeros(size(labelNew));
SE = strel('square',2);

for ii = 1:max(max(labelNew))
    if sum(sum(labelNew == ii)) > 0
        imBW = zeros(size(labelNew));
        imBW(labelNew == ii) = 1;
        imBW = imdilate(imBW,SE);
        outlinesNew = outlinesNew + bwperim(imBW);
    end
end

cd(configVar.rootPath)
outputFolderName = strcat(file_name,'_Segmentation');
if 7 ~= isfolder(outputFolderName)
    mkdir(outputFolderName)
else
    rmdir(outputFolderName,'s')
    mkdir(outputFolderName)
end
cd(strcat('.\',outputFolderName))

imwrite(outlinesNew, 'Outlines.tif');
imwrite(labelNew, 'Labels.tif');

cd(configVar.rootPath)
end