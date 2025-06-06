function run_make_group_anat(subs)
%RUN_MAKE_GROUP_ANAT makes a custom group-average anatomical image
%of an MRI data set
%   Although there are standard anatomical images available in SPM analysis
%   software (in MNI152 space), it might be useful to create a custom anatomical
%   image that accurately reflects the (average) anatomy of your own
%   specific sample. 
%   The RUN_MAKE_GROUP_ANAT function makes such a custom template
%   for your own data set by:
%   1) performing spatial normalization of subject-level anatomical images
%   to MNI152 space
%   2) averaging over the normalized images to create one anatomical image
%   for the whole group
%
%   This new, custom anatomical image can be used for visualization of fMRI
%   results. Note that since this new image is still in MNI152, this has no
%   consequences for the spatial interpretation of your effects. You can
%   also continue to use your standard MNI-based ROIs.
%
%   RUN_MAKE_GROUP_ANAT(subs) runs the analysis for all subjects indicated
%   in the subs input variable, which needs to be a vector of integers
%   indicating the subject numbers.
%   Input can also be ommitted, in which case the function
%   defaults to a preset set of subject numbers (can be adjusted manually
%   inside the function)
%
%   Note:
%   - This function assumes you have SPM12 installed. If you're running this
%     function on a local SPM12 installation or outside of the DCCN cluster,
%     please adjust the 'Preparation' section accordingly so that it
%     correctly loads SPM12.
%   - This function also assumes your data set has a BIDS structure when
%     loading the subject data
%
% written by Felix Klaassen, August 2022

%% Preparation
% check input
if nargin < 1
    subs = [0:2,4:10,12,14:18,20:28,30:34,36:49,51:53,55:63,65,66]; % default subject numbers for the AA-FREEZE study
end

% load SPM12
LoadSPM; % custom function to load SPM12 from /home/common/matlab/spm12

%% Normalize anatomical images
% pre-create temporary folder to store normalized images in
if exist('norm_imgs_temp','dir')
    rmdir('norm_imgs_temp');
end
mkdir('norm_imgs_temp');

% loop over subjects
for s = 1:length(subs)
    % load clean SPM batch for spatial normalization to MNI152
    load('norm_anat_batch.mat','matlabbatch');

    % get sub data
    if subs(s) == 0
        SUBJNAME = 'sub-00x';
    elseif subs(s) < 10 
        SUBJNAME = ['sub-00' num2str(subs(s))];
    elseif subs(s) < 100
        SUBJNAME = ['sub-0' num2str(subs(s))];
    else
        SUBJNAME = ['sub-' num2str(subs(s))];
    end

    padi = i_aafreeze_infofile(SUBJNAME);

    % change subject code
    matlabbatch = struct_string_replace(matlabbatch, 'sub-001', char(SUBJNAME));

    % change voxel size?
    matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [1 1 1]; % default [2 2 2]

    % run batch
    fprintf('Normalizing subject %i...\n',subs(s))
    spm_jobman('run',matlabbatch);

    % move normalized anat to temp folder
    fprintf('Moving file to temporary folder...\n')
    anatfile = dir(fullfile(padi.anat,'w*.nii'));
    movefile(fullfile(anatfile.folder, anatfile.name),['norm_imgs_temp' filesep anatfile.name])

end

fprintf('Done!\n')

%% Average normalized anatomical images
% load batch
clear matlabbatch
load avg_anat_batch.mat matlabbatch

% update list of images
addpath norm_imgs_temp
anatfiles = dir('norm_imgs_temp/w*');
matlabbatch{1}.spm.util.imcalc.input = {anatfiles.name}';
for i = 1:numel(matlabbatch{1}.spm.util.imcalc.input)
    matlabbatch{1}.spm.util.imcalc.input{i} = strcat('norm_imgs_temp',filesep,matlabbatch{1}.spm.util.imcalc.input{i},',1');
end

% run the job
fprintf('Averaging all anatomical images...\n')
spm_jobman('run',matlabbatch);

fprintf('Done!\n')

%% Clean-up [remove intermediate files]
% remove subject-level normalized images
rmdir('norm_imgs_temp','s')

end

