% Example config file for the research unit (RU) preprocessing pipeline
% ---------------------------------------------------------------------

%% Preparation
% Initialization
% --------------

clc
close all
clearvars

% Directories
% -----------
% Get the parent directory of the current directory 
% (assumed to contain the BIDS directory)
parentDir = fullfile('C:\Users','klaassen','Documents','Research Unit 5389','General','fMRI pipeline');
% parentDir = fileparts(pwd);

% SPM12/SPM25 directory
% for example: spmPath = fullfile(parentDir,'spm12/');
spmVersion = 12; %12 or 25
assert(any([12, 25] == spmVersion), 'Unknown SPM version')
spmPath = fullfile('C:\Users','klaassen','Documents','MATLAB',['spm' num2str(spmVersion)]);
addpath(spmPath)

% Data source- and target root directory
dsRoot = fullfile(parentDir,'data'); %your BIDS folder
preRoot = fullfile(dsRoot,'derivatives'); %where the preprocessed data will be placed
funcLab = 'func'; % label for functional data sub directory
anatLab = 'anat'; % label for anatomical data sub directory
fmapLab = 'fmap'; % label for field-map data sub directory
% behavLab = 'beh'; % label for behavioral data sub directory
% physLab = 'phys'; % label for physiological data sub directory

% Subject directories
% E.g., subDir = {'sub-001', 'sub-002', 'sub-003'};
%todo if necessary: add option to switch between two-digit and three-digit subject numbers?
subDir = dir(fullfile(dsRoot,'sub*'));
allSubjects = {subDir.name}';

% Define all run numbers per subject
%e.g., run_sel{1} = {[1], [1:6]}; % sub-001 has 1 run for task 1, and 6 runs for task 2
runSel = cell(1,numel(subDir));
for i = 1:length(allSubjects)
    runSel{i} = {1:4};
end
assert(numel(allSubjects) == numel(runSel), 'Length of subject- and run lists should match!')

% BIDS format file name part labels
BIDSlabel{1} = {'task-PT'}; % BIDS file name task label: BIDSlabel{1} = {'task1';'task2')
BIDSlabel{2} = ''; % BIDS file name acquisition label
BIDSlabel{3} = 'run-0'; % BIDS file name run index
BIDSlabel{4} = 'bold'; % BIDS file name modality suffix

%% Select preprocessing steps and settings
% Change the settings in this section to accomodate your specific 
% project/sequence/pipeline
%   1. Slice-timing correction
%   2. Unwarping/realignment   
%   3. Coregistration of mean EPI to T1
%   4. Segmentation T1 image                                (optional)
%   5. Normalization of EPI data                            (optional?)
%   6. Smoothing                                            (optional)

% Select subjects to preprocess
% 'subs2incl' should be cell array with your BIDS-compliant numbers: subs2incl = {'001','002','051'}, or 'all' to preprocess all subjects in dsRoot
subs2incl = {'203'};

% Select which preprocessing steps to perform
stepSlicetiming     = false;
stepUnwarping       = false; % only if realignment == false
stepRealignment     = false; % only if unwarping == false
stepCoregistration  = false;     
stepSegmentation    = true;
stepNormalization   = false; 
stepSmoothing       = false;

overwriteFiles = false; % overwrite existing preproc files?
deleteFiles = false;    % delete intermediate preproc files?

% Define prefixes
prefix.slicetiming      = 'a';
prefix.unwarping        = 'u';
prefix.realignment      = 'r';
prefix.coregistration   = 'c'; % only used for mean image and if reslicing EPIs
prefix.normalization    = 'w';
prefix.smoothing        = 's';
firstPrefix = prefix.realignment; % determines which files to use for first preprocessing step. Default (i.e., use raw nifti's): firstPrefix = '';

% Define preprocessing parameters (currently match example dataset)
nSlices = 66;
TR = 1.975; % in seconds
refSlice = (TR/2)*1000; % in ms
sliceTimings = [1.91499999998,1.85499999998,1.79499999998,1.73499999999,1.67499999999,1.61499999999,1.55499999999,1.495,1.435,1.375,1.315,...
                1.25749999998,1.19749999998,1.13749999998,1.07749999998,1.01749999999,0.95749999999,0.89749999999,0.83749999999,0.7775,0.7175,0.6575,...
                0.5975,0.53749999998,0.47749999998,0.41749999998,0.35999999999,0.29999999999,0.23999999999,0.17999999999,0.12,0.06, 0,...
                1.91499999998,1.85499999998,1.79499999998,1.73499999999,1.67499999999,1.61499999999,1.55499999999,1.495,1.435,1.375,1.315,...
                1.25749999998,1.19749999998,1.13749999998,1.07749999998,1.01749999999,0.95749999999,0.89749999999,0.83749999999,0.7775,0.7175,0.6575,...
                0.5975,0.53749999998,0.47749999998,0.41749999998,0.35999999999,0.29999999999,0.23999999999,0.17999999999,0.12,0.06,0]; % in seconds
epiReadoutTime = 0.03359989248034406; % in seconds
voxelSize = [2, 2, 2]; % [x,y,z,] EPI voxel size in mm

%% Apply settings to preprocessing variables object
% Don't change stuff in this section unless you know what you're doing

% Initialize preprocessing variables object
prepVars = preprocessingVars();

% Update paths and labels
prepVars.spmPath = spmPath;
prepVars.dsRoot = dsRoot;
prepVars.funcLab = funcLab;
prepVars.anatLab = anatLab;
prepVars.fmapLab = fmapLab;
prepVars.preRoot = preRoot;
prepVars.BIDSlabel = BIDSlabel;
prepVars.overwriteFiles = overwriteFiles;
prepVars.deleteFiles = deleteFiles;

% Update subjects and runs
if any(contains(subs2incl,'all'))
    sub_idx = 1:numel(allSubjects);
else
    sub_idx = find(contains(allSubjects,subs2incl));
end
prepVars.subjects = allSubjects(sub_idx); % selected subjects
prepVars.runSel = runSel(sub_idx); % update nr of functional runs for selected subjects

% Update steps
prepVars.stepSlicetiming = stepSlicetiming;
prepVars.stepUnwarping = stepUnwarping;
prepVars.stepRealignment = stepRealignment;
prepVars.stepCoregistration = stepCoregistration;
prepVars.stepSegmentation = stepSegmentation;
prepVars.stepNormalization = stepNormalization;
prepVars.stepSmoothing = stepSmoothing;
%todo - add option to do coregistration between two functional runs (if ppt left scanner in-between functional runs)
%todo - add option to do non-linear coregistration (e.g., instead of fmap correction; see büchel pipeline)

% Order of preprocessing steps
prepVars.preprocessingComponents = [stepSlicetiming,...
                                    stepUnwarping,...
                                    stepRealignment,...
                                    stepCoregistration,...
                                    stepSegmentation,...
                                    stepNormalization,...
                                    stepSmoothing];

% Update prefixes
prepVars.prefix.slicetiming = prefix.slicetiming;
prepVars.prefix.unwarping = prefix.unwarping;
prepVars.prefix.realignment = prefix.realignment;
prepVars.prefix.normalization = prefix.normalization;
prepVars.prefix.smoothing = prefix.smoothing;
if exist('firstPrefix', 'var') && ~isempty(firstPrefix)
    prepVars.currPrefix = firstPrefix;
end

% Update fMRI parameters
prepVars.nSlices = nSlices;
prepVars.TR = TR;
prepVars.refSlice = refSlice;
prepVars.sliceTiming = round(sliceTimings*1000); % convert to ms
prepVars.epiReadoutTime = round(epiReadoutTime*1000); % convert to ms
prepVars.voxelSize = voxelSize;

%% Run preprocessing 
% Initialize preprocessing object
prepObj = preprocessingObj(prepVars);

% Call the function that implements preprocessing across subjects
prepObj.preprocessLoop();
