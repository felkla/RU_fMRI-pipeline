function [hdr] = getDicInfo(dicompath)
% dicompath='yourpath/sub-001/etc/';

if nargin == 0
    dicompath = input('Please type the path to your DICOM files: \n');
end

if strcmp(dicompath, 'curr')
    dicompath = pwd;
end

dicomfiles=dir([dicompath,'/','*.IMA']);

hdr = cell(1,length(dicomfiles));

for images=1:length(dicomfiles)
    
    %get header information
    hdr_dicomfile=dicominfo(fullfile(dicompath,dicomfiles(images).name));
    
    disp(hdr_dicomfile.SeriesDescription)
    hdr{images} = hdr_dicomfile;
    
end


end