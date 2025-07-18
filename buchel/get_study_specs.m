function [path,vars,analysis,import,qc] = get_study_specs

%% path definitions
if ispc
    path.baseDir     = fullfile('C:\Users\klaassen','Documents','Research Unit 5389','DynTBU','Projects','Telos');
elseif isunix
    path.baseDir     = fullfile('/home','klaassen','projects','telos');
end
path.templateDir    = [pwd filesep 'templates'];
path.derivDir       = fullfile(path.baseDir, 'derivatives');
path.preprocDir     = fullfile(path.baseDir, 'data'); % the BIDS folder
path.backupDir      = fullfile(path.baseDir, 'backup'); % where nii.gzip backups will be stored
path.firstlevelDir  = fullfile(path.baseDir, 'derivatives', 'spm_firstlevel');
path.secondlevelDir = fullfile(path.baseDir, 'derivatives', 'spm_secondlevel');

vars.max_procs   = 12; % how many parallel processes
vars.parallel    = 1;  % parallel processing?

import.prisma       = {{26380},{26387},{26409},{26411},{26416}}; % translates to PRISMA_nnn
import.prisma_no    = [1,2,3,4,5]; % subject number
sex                 = ['m','m','m','f','m']; 
age                 = [24,22,37,28,24];

%snippet showing how to make a .tsv file from such a structure
x.participant_id = cellstr(spm_file(num2str(import.prisma_no','%2.3d'),'prefix','sub-'));
x.sex            = sex';
x.age            = age';
x.scan_id        = cell2mat(cellfun( @(x) [cell2mat(x)], import.prisma, 'UniformOutput', false ))';
spm_save(fullfile(path.preprocDir,'participants.tsv'),x); % write a participants.tsv to BIDS folder

%% Import related stuff
import.prisma        = fullfile(path.preprocDir,'participants.tsv'); % tsv file providing PRISMA # (preferred)

import.user          = 'klaassen';
import.server        = 'revelations.nin.uke.uni-hamburg.de';

hh = 1;
import.data(hh).dir        = 'func';
import.data(hh).type       = 'bold';
import.data(hh).seq        = 'ninEPI_bold_v12C, fMRI '; %protocol name (trailing space makes it unique)
import.data(hh).cond       = 'n == 517'; % heuristic to get only valid runs (e.g. more than 1000 volumes)
hh = hh + 1;

import.data(hh).dir        = 'anat'; % valid BIDS dir name
import.data(hh).type       = 'T1w'; % valid BIDS file name
import.data(hh).seq        = 'ninFLASH_v14A_df, mprage, defa-SAT_DEFA ';
import.data(hh).cond       = 'n == 240'; % heuristic to get only valid runs (e.g. exactly 240 slices)
hh = hh + 1;

import.data(hh).dir        = 'fmap';
import.data(hh).type       = 'magnitude';
import.data(hh).seq        = 'gre_field_map, 3mm, filter M ';
import.data(hh).cond       = 'n == 132'; % was 120
hh = hh + 1;

import.data(hh).dir        = 'fmap';
import.data(hh).type       = 'phasediff';
import.data(hh).seq        = 'gre_field_map, 3mm, filter M ';
import.data(hh).cond       = 'n == 66'; % was 60
hh = hh + 1;

% Specific runs can be excluded even if they match the criteria above see
% sbp_import_data.m for details on how to mark this in participants.tsv

import.dummies            = 0; % these scans are removed when merging 3D epifiles to a 4D file

%% vars definitions

% various predefined names (change only if you know what you are doing)
vars.skullStripID    = 'skull-strip-T1.nii';
vars.T1maskID        = 'brain_mask.nii';
vars.templateID      = 'cb_Template_%d_Dartel.nii';
vars.templateT1ID    = 'cb_Template_T1.nii';
vars.groupMaskID     = 'neuromorphometrics.nii';
vars.brainstemID     = 'Cerebellum_SUIT_05.nii'; % or 'brainstem_mask.nii'
vars.templateStripID = 'cb_Template_SkullStrip.nii';

% this need to be adapted to your study / computer--------------
vars.task  = 'PT';
vars.nRuns = 4;
vars.nSess = 1;
% get info for slice timing correction MUST BE in ms //FK not used!
vars.sliceTiming.so = []; % in ms

vars.sliceTiming.tr = 1.975; % in s
% TR and slice timing info can be found (after import) in task-XXX_bold.json

vars.sliceTiming.nslices  = 66;
vars.sliceTiming.refslice = (vars.sliceTiming.tr*1000)/2; %AGAIN in ms, default is 0.5 * TR

%% QC settings
%file name for mov regressors
qc.movFilename  = 'noise_mov_rasub-%02d_ses-%02d_task-%s_run-%02d_bold.mat';

%thresholds for movement inspection
qc.threshSpike     = 0.7; %threshold for spikes
qc.threshMov       = 3; %threshold for overall movement within 1 run or between runs
qc.percSpike       = 0.05; %threshold in % in number of volumes that are discarded because of spikes

% display options

qc.maxDisImg       = 7; %number of subject images displayed at once (not all numbers make sense here, 7 means a 4x2 display including template, otherwise try 5(3x2))
qc.contour         = 1; %1: template contour is displayed on images; 0: is not displayed

% first level related qc

qc.tThresh         = 1.7; %t-value threshold, only values above this threshold will be shown
qc.tMapSmoothK     = 4; %smoothing kernel for t-map
qc.overlayColor    = [1 0 0]; %color for overlay (here red)

%% rsa section
% searchlight based RSA definitions
rsa.searchopt      = struct();
rsa.searchopt.def  = 'sphere';
rsa.searchopt.spec = 8; % mm

% atlas based RSA definitions
rsa.atlas    = 'MNI_Asym_Schaefer2018_400Parcels_17Networks_order';
rsa.roi_ind  = []; % take all
rsa.valid    = 0.9; % only rois with > 90% coverage
rsa.lss      = 1; % use lss betas yes/no
rsa.mnn      = 0; % multivariate noise normalization yes/no; CAVE slow for searchlight
rsa.mnn_lim  = 128; % zuse only n scans to calculate residuals
rsa.ana_name = 'Conc_mov24_wm_csf_roi_lcpa_lsa_rdm_-2_none'; % where the betas come from

% define which stims to use
% these are RegExp and all beta images that fit the expression are averaged  
rsa.stims = {'Fac_05','Fac_06','Fac_07','Fac_08','Hou_01','Hou_02','Hou_03','Hou_04','Mix_15','Mix_16','Mix_17','Mix_18','Mix_25','Mix_26','Mix_27','Mix_28','Mix_35','Mix_36','Mix_37','Mix_38','Mix_45','Mix_46','Mix_47','Mix_48'};

% define candidate RDMs
rsa.models{1}.RDM   = []; %specify your RDM here
rsa.models{1}.name  = 'faces';

rsa.models{2}.RDM   = []; %specify your RDM here
rsa.models{2}.name  = 'houses';

%% Analysis settings
% the next section can be used to define different groups for 2nd level analysis
analysis.all_subs  = [8:25 27:50]; % very all;
single_group       = ones(size(analysis.all_subs));
analysis.group_ind  = single_group; %index 1
analysis.group_weights = [1];
analysis.group_names   = {'All'};

% bias_run           = [0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0]; %1 = hi bias in 1st run
% analysis.group_ind  = bias_run+1; %index 1 and 2
% analysis.group_weights = [1 1;1 -1;-1 1];
% analysis.group_names   = {'All','lo_bias_1st>otherwise','hi_bias_1st>otherwise'};

% analysis.group_ind  = single_group; %index 1
% analysis.group_weights = [1];
% analysis.group_names   = {'All'};

analysis.noise_corr        = ['mov24_wm_csf_roi']; % can contain any combination of "mov6" "mov24" "wm" "csf" "roi" "physio"
%analysis.noise_corr        = ['mov24_wm'];
%analysis.noise_corr        = ['physio'];
%analysis.noise_corr        = [];
analysis.cvi               = 'none'; % any of "AR(1)"  "FAST" "none" "wls" the latter uses J. Diedrichsen toolbox to do WLS https://www.diedrichsenlab.org/imaging/robustWLS.html
analysis.shift             = 0; % shift all onsets by n TRs 
analysis.skernel           = 6; % smoothing kernel
analysis.hpf               = 120;
analysis.bs                = 0; % do brainstem specific analysis (not fully implemented yet)
analysis.use_vasa          = 1; % do vasa correction https://www.sciencedirect.com/science/article/pii/S1053811915008484

analysis.sess              = [1]; % which sessions to analyze (can be a vector)
analysis.prune             = 1;   % use only scnas that are relevant (e.g. skip scans at the end when there are no more stimuli)

% what to do 1st level
analysis.do_model          = 0; % specify the model
analysis.do_est            = 0; % estimate the model
analysis.do_vasa           = 0; % estimate vasa image for correction
analysis.do_cons           = 0; % do contrasts
analysis.do_correct_vasa    = 0; % correct beta/con images using vasa image
analysis.do_warp           = 0; % warp native space con or beta images to template space
analysis.do_smooth         = 1; % smooth these warped beta and con images

% what to do at the second level
analysis.fact_dept         = 0; % account for diff covariances at the 2nd level ANOVA
analysis.fact_var          = 1; % ... or only variances
analysis.do_fact           = 1; % simple anova that reproduces the 1st level anlysis at the 2nd level
analysis.do_fact_con       = 1; % do all contrasts at the second level

analysis.do_one_t         = 0; % instead use the estimated cons from 1st level and do one sample t tests

% what to do
do_hrf_param  = 0;
do_hrf_cond   = 1;
do_fir        = 0;
do_lsa        = 0;


if do_hrf_param
    [analysis.t_con, analysis.t_con_names] = get_hrf_cons_param;
    [analysis.f_con, analysis.f_con_names] = get_hrf_Fcons_param; %only performed at the 2nd level
    analysis.concatenate       = 1; % concatenate or not ?
    analysis.ana               = 2; % hrf
    analysis.n_base            = 1;
    analysis.name_ana          = 'lcpa_hrf_param';
    analysis.events            = '_param'; % this refers to the tsv file: e.g. sub-08_ses-01_task-lcpa_run-01_events_param.tsv
    analysis.cond_names        = {'vis'        ,'mix'  ,'pain'}; % three conditions
    analysis.p_mod             = {{'p_vistype'},{}     ,{'p_painint'}}; % vis and pain have 1 or 2 parametric modulators
    %analysis.p_mod             = {{}           ,{}     ,{}}; 
end

if do_hrf_cond
    [analysis.t_con, analysis.t_con_names] = get_hrf_cons_cond;
    
    analysis.concatenate       = 1; % concatenate or not ?
    analysis.ana               = 2; % hrf
    analysis.n_base            = 1;
    analysis.name_ana          = 'lcpa_hrf_cond';
    analysis.events            = '_cond'; % this refers to the tsv file: e.g. *_cond.tsv
    analysis.cond_names        = {'house','mix','face'}; % 
    analysis.p_mod             = {{}     ,{}    ,{}   }; 
end


if do_fir
    analysis.concatenate       = 1;
    analysis.t_con             = [];
    analysis.t_con_names       = [];
    analysis.ana               = 1; % fir
    analysis.n_base            = 10;
    analysis.name_ana          = 'lcpa_fir';
    analysis.events            = '_param'; % this refers to the tsv file: e.g. *_param.tsv
    analysis.cond_names        = {'pain'}; % only pain
    analysis.p_mod             = {{'p_painint'}};
end


if do_lsa
    analysis.concatenate       = 1;
    analysis.t_con             = [];
    analysis.t_con_names       = [];
    analysis.ana               = 3; % lsa
    analysis.lss               = 1; % also do LSS
    analysis.n_base            = 1;
    analysis.name_ana          = 'lcpa_lsa';
    analysis.events            = '_lsa'; % this refers to the tsv file: e.g. *_lsa.tsv
    analysis.cond_names        = {'face'        ,'house'  ,'mix'};
    analysis.p_mod             = {{}            ,{}       ,{}   };
end


    function [t_con, t_con_names] = get_hrf_cons_cond
        
        t_con = [1  0  0;...
            0  1  0;...
            0  0  1;...
            1 -1  0;...
            -1  1  0;...
            1  0 -1;...
            -1  0  1;...
            0  1 -1;...
            0 -1  1;...
            1 -2  1;...
            -1  2 -1];
        t_con_names         = {'house','mix','face','h>m','m>h','h>f','f>h','m>f','f>m','hf>m','m>hf'};
    end

    function [t_con, t_con_names] = get_hrf_cons_param
        
        t_con = [1  0   0   0 0;...
            0  0   1   0 0;...
            0  0   0   1 0;...
            0  1   0   0 0;...
            0 -1   0   0 0;...
            0  0   0   0 1];
        t_con_names         = {'vis','mix','pain','h_f','f_h','p_param'};
    end
    function [f_con, f_con_names] = get_hrf_Fcons_param
        
        f_con{1} = [eye(2) zeros(2,3)];
        f_con{2} = [zeros(1,2) 1 zeros(1,2)];
        f_con{3} = [zeros(2,3) eye(2)];
        
        f_con_names         = {'vis','mix','pain'};
    end
end