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
% NOTE: This function calls 'extract_BOLD_data.m', so make sure it's been added 
% to the path.
%
% Felkla 2022
%% select paths and images
% add lindvoo's functions to path
addpath /home/klaassen/toolboxes/randomfunctions-master/Matlab/

% define root path
rootpath = '/projects/crunchie/predator/pilot';

% set subjnr
subnr = input('Please input subject number (1 or 2): ');

% get sequence names to loop over (in this case, separate pilots)
if subnr == 1
    prismanr = 'PRISMA_26016';
    contrastnames = {'ninEPI_B12BSMS3_0002','ninEPI_B12B125mminplane_0005'};
    maskpath = fullfile(rootpath,'masks','pilot01');
elseif subnr ==2
    prismanr = 'PRISMA_26069';
    contrastnames = {'ninEPI_B12B15mmSMS2AP_0002','ninEPI_B12B20mmslcnogap_0003',...
        'ninEPI_B12BSMS3_0004','ninEPI_B12B125mminplane_0005'};
    maskpath = fullfile(rootpath,'masks','pilot02');
end

% preallocate output variables
sigextr = NaN(1,numel(contrastnames));

% loop over contrasts
for i = 1:length(contrastnames)
    contrast = contrastnames{i};

    % path to the images from which to extract the signal
    inputim.path = ['/projects/crunchie/predator/pilot/analysis/fMRI/tSNR/',prismanr,'/',contrast,'/'];

    % images from which to extract the signal
    inputim.ims = dir([inputim.path 'tSNR*.nii']);
    assert(~isempty(inputim.ims), 'Error: Couldn''t find any images in this path.')
    inputim.ims = {inputim.ims.name}'; % convert to cell array (SPM req.)

    % the roi template (e.g. binary mask)
    if subnr == 1
        if strcmp(contrast,'ninEPI_B12BSMS3_0002')
            roitemplate = fullfile(maskpath,'rPAG_5-3_-2_14_SMS3_1p5inplane.nii'); %make sure to pick the resliced image
        elseif strcmp(contrast,'ninEPI_B12B125mminplane_0005')
            roitemplate = fullfile(maskpath,'rPAG_5-3_-2_14_SMS3_1p25inplane.nii'); %make sure to pick the resliced image
        end
    elseif subnr == 2
        if strcmp(contrast,'ninEPI_B12B15mmSMS2AP_0002')
            roitemplate = fullfile(maskpath,'rPAG_5-2_4_21_SMS2_1p5iso.nii'); %make sure to pick the resliced image
        elseif strcmp(contrast,'ninEPI_B12B20mmslcnogap_0003')
            roitemplate = fullfile(maskpath,'rPAG_5-2_4_21_SMS2_1p5inplane.nii'); %make sure to pick the resliced image
        elseif strcmp(contrast,'ninEPI_B12BSMS3_0004')
            roitemplate = fullfile(maskpath,'rPAG_5-2_4_21_SMS3_1p5inplane.nii'); %make sure to pick the resliced image
        elseif strcmp(contrast,'ninEPI_B12B125mminplane_0005')
            roitemplate = fullfile(maskpath,'rPAG_5-2_4_21_SMS3_1p25inplane.nii'); %make sure to pick the resliced image
        end
    end

    % value of the coordinates in the mask (it will look for coordinates relative to that value)
    extrval = 0;
    direction = 2; % finds voxels in template with value larger than 0

    %% Run the extraction and save to disk
    [sigextr(i), roixyz] = extract_BOLD_data(inputim, roitemplate, extrval, direction);
    
%     save(fullfile(inputim.path,'extr_PAG.mat'), 'sigextr', 'roixyz');
%     writematrix(sigextr',fullfile(inputim.path,'extr_vmPFC_LR.csv'));
end
