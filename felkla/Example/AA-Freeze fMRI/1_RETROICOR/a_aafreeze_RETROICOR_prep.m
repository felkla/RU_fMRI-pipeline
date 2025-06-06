function a_aafreeze_RETROICOR_prep(SUBJNR,padi)
%% Description
% Uses BrainAmpConverter (BAC) to convert BrainAmp physiological data to
% formats compatible with HERA and Autonomate. Can be used in preparation
% for create RETROICOR regressors for fMRI analysis.
%
% CREDIT: 
% Wrapper function by Felix Klaassen, 2021
% BAC & HERA scripts by Erno Hermans & Linda de Voogd
% See Glover, Li, & Ress (2000) for the original paper on RETROICOR

%% Input
if ~exist('SUBJNR','var')
    SUBJNR = input('Please input subject number: ');
end
if SUBJNR < 10 || SUBJNR == 'x'
    SUBJNAME = ['sub-00' num2str(SUBJNR)];
elseif SUBJNR < 100
    SUBJNAME = ['sub-0' num2str(SUBJNR)];
else
    SUBJNAME = ['sub-' num2str(SUBJNR)];
end

%% Create output directories
if ~exist(padi.hera,'dir')
    mkdir(padi.hera)
end
if ~exist(padi.scr,'dir')
    mkdir(padi.scr)
end

%% Convert data with BrainAmpConverter to accommodate HERA style
% Run wrapper function for convenience
convertphysdata(SUBJNR,padi);

% move output to subject folders
phys.hera = dir([fullfile(padi.phys),filesep,'*_hera*']);
phys.autonomate = dir([fullfile(padi.phys),filesep,'*_autonomate*']);

% heart rate
for f = 1:numel(phys.hera)
    movefile([phys.hera(f).folder,filesep,phys.hera(f).name],padi.hera);
end

% skin conductance
for f = 1:numel(phys.autonomate)
    movefile([phys.autonomate(f).folder,filesep,phys.autonomate(f).name],padi.scr);
end
