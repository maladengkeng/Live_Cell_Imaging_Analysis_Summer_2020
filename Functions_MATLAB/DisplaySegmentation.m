function [] = DisplaySegmentation(configVar, file_name, outlinesNew, labelNew, outlines, label)
cd(configVar.rootPath)
cd(strcat(configVar.pathToOutput))
try
    phase_contrast = imread(strcat(file_name,'_t001xy1c1.tif'));
catch
    phase_contrast = imread(strcat('.\raw_im\',file_name,'_t001xy1c1.tif'));
end
phase_contrast(outlinesNew == 1) = 0;
imshow(phase_contrast)
PC_rgb = cat(3,phase_contrast,phase_contrast,phase_contrast);
outlines_rgb = cat(3,outlinesNew .* 2^16, zeros(size(outlinesNew)),zeros(size(outlinesNew)));

outlines_rgb_old = cat(3,outlines .* 2^16, zeros(size(outlines)),zeros(size(outlines)));

numCellsOld = numel(unique(label));
numCellsNew = numel(unique(labelNew));

figure()
subplot(1,2,1)
imshow(PC_rgb + uint16(outlines_rgb_old))
title(strcat("Original SuperSegger segmentation, # Cells: ",num2str(round(numCellsOld))))
subplot(1,2,2)
imshow(PC_rgb + uint16(outlines_rgb))
title(strcat("Final output segmentation, # Cells: ",num2str(round(numCellsNew))))

end