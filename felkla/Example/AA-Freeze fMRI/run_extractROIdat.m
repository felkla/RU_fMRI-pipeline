%% run_extractROIdat
% This is a wrapper that implements the extraction of any signal 
% (raw/preprocessed/beta's) from any ROI for (f)MRI data.
% The heavy lifting is done by two functions written by lindvoo.
%
% This wrapper assumes that you have already created a binary mask for the
% ROI from which you want to extract the signal. You can do this in SPM.
% This script uses that mask as follows:
%
% extract_BOLD_data.m 
% INPUT:
% 	inputim.path - Path to the images from which to extract the signal; 
% 	inputim.ims  - Cell array with the images from which to extract the signal; 
% 	roitemplate  - The binary mask; 
% 	extrval      - Value of the coordinates in the mask 
%                It will look for coordinates with value 
%                equal to/larger/smaller than extrval (indicated by
%                direction)
% 	direction    - 1=equal to, 2=larger, 3=smaller
% 
% OUTPUT:
% 	sigextr - average signal within the mask of the images
% 	roixyz  - list of coordinates from which sigextr is taken
% 
% NOTE: This function calls 'threeDfind.m', so make sure it's been added 
% to the path.
%
% Felkla 2022
%% select paths and images
% add lindvoo's functions to path
addpath /project/3023009.03/randomfunctions-master/Matlab/ 

% set some parameters (model, contrast, etc.)
modelnr = input('Please input model name (1=factorial, 2=parametric, 3=freezing, 4=FIR): ');
if modelnr == 1
    model = 'factorial';
elseif modelnr == 2
    model = 'parametric';
elseif modelnr == 3
    model = 'freezing';
elseif modelnr == 4
    model = 'FIR';
end

% get paths
addpath 4_secondlevel; padi = i_aafreeze_paths(DESIGN); 

% get contrast names to loop over
contrasts = dir([padi.savepath,filesep,'T_*']);
contrastnames = {}; [contrastnames{1:length(contrasts),1}] = deal(contrasts.name);

% load SPM
LoadSPM;

% loop over contrasts
for i = 1:length(contrastnames)
    contrast = contrastnames{i};

    % path to the images from which to extract the signal
    inputim.path = ['/project/3023009.03/stats/fMRI/',model,'/groupstats/',contrast,'/'];

    % images from which to extract the signal
    inputim.ims = dir([inputim.path '*.nii']);
    assert(~isempty(inputim.ims), 'Error: Couldn''t find any images in this path.')
    inputim.ims = {inputim.ims.name}'; % convert to cell array (SPM req.)

    % the roi template (e.g. binary mask)
    % roitemplate = fullfile(inputim.path, 'one_sample_ttest', 'AMY_R_neg_34_2_-22.nii');
    roitemplate = fullfile(padi.maskpath,'resliced','rvmPFC_AAL3.nii');

    % value of the coordinates in the mask (it will look for coordinates relative to that value)
    extrval = 0;
    direction = 2; % finds voxels in template with value larger than 0

    %% Run the extraction and save to disk
    [sigextr, roixyz] = extract_BOLD_data(inputim, roitemplate, extrval, direction);
    
    save(fullfile(inputim.path,'extr_vmPFC_LR.mat'), 'sigextr', 'roixyz');
    writematrix(sigextr',fullfile(inputim.path,'extr_vmPFC_LR.csv'));
end
