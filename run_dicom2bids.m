function run_dicom2bids(subnrs)
%Dicom2Bids Wrapper function to convert DICOMs to BIDS-formatted nifti's.
%   This function takes as input the subject numbers (corresponding to the
%   eventual 'sub-00x' numbers in BIDS format) and subsequently runs the
%   BIDS-conversion script from the Büchel lab. This works well for data
%   collected and stored at the UKE.

if nargin < 1
    subnrs = 1;
end
addpath(genpath('buchel'))
sbp_import_data(subnrs)

end