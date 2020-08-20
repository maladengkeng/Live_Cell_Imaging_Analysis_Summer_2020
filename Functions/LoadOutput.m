function [label, outlines, properties] = LoadOutput(configVar)
cd(configVar.rootPath)
listing = dir(strcat(configVar.pathToOutput,...
    '\xy1\seg'));
listing = struct2cell(listing);
name = listing{1,end};
seg = load(strcat(configVar.pathToOutput,...
    '\xy1\seg\',name));

outlines = seg.segs.segs_3n + seg.segs.segs_good;
label = watershed(outlines);

properties = regionprops(label,'all'); % Properties contains various relevant parameters of segmented cells
end