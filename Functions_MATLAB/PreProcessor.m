function [] = PreProcessor(file_name,configVar)
% This function improves the segmentability of a phase contrast image
% by homogenizing the intensity and filtering the background.
cd(configVar.rootPath)
cd(configVar.pathToData)
im = uint16(imread(strcat(file_name,'.tif')));
mask = imgaussfilt(im, 30);
inv_mask = max(max(mask))-mask;
improved_im = imadjust(im+inv_mask);

[gradientThreshold,~] = imdiffuseest(improved_im,'ConductionMethod' ,'quadratic');
further_improved_im = imdiffusefilt(improved_im,'GradientThreshold',gradientThreshold,'numberOfIterations' ,2);

cd(configVar.rootPath)
if 7 == exist(configVar.pathToOutput, 'dir')
    rmdir(configVar.pathToOutput, 's')
end
mkdir(configVar.pathToOutput)

cd(configVar.pathToOutput)
imwrite(further_improved_im, strcat(file_name,'_t001xy1c1.tif'));
imwrite(further_improved_im, strcat(file_name,'_t001xy1c2.tif'));

cd(configVar.rootPath)

figure()
subplot(1,2,1)
imshow(uint16((double(im).*2^16)./double(max(max(im)))))
title('0riginal image')
set(gca, 'FontSize',20)

subplot(1,2,2)
imshow(uint16((double(further_improved_im).*2^16)./double(max(max(further_improved_im)))))
title('Image after corrections')
set(gca, 'FontSize',20)

end


