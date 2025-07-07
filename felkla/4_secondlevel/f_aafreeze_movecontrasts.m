function f_aafreeze_movecontrasts(DESIGN)
% f_aafreeze_movecontrasts
% Function to move contrast images to a group-level folder in preparation
% for second-level analysis
%
% Felix Klaassen 2022

%% Preparation
% set input
if ~exist('DESIGN','var')
    DESIGN = input('Please input the model design (''factorial'',''parametric''): ');
end

%paths
padi = i_aafreeze_paths(DESIGN);

%load first level batch to get the contrast names
if strcmp(DESIGN,'factorial')
    load(fullfile('..','3_firstlevel','batchFiles','f_aafreeze_firstlevel.mat'))
elseif strcmp(DESIGN, 'parametric')
    load(fullfile('..','3_firstlevel','batchFiles','f_aafreeze_firstlevel_pmod.mat'))
else
    error('Undefined second level batch file for ''DESIGN'' variable: ''%s''',DESIGN);
end

%make dir
if exist(padi.savepath,'dir'); rmdir(padi.savepath,'s'); end %remove when exists
mkdir(padi.savepath);

%warning off;mkdir(padi.savepath);warning on;

%% Perform copying
%loop over contrast to extract the name
contrastnames = [];
for c_con = 1:numel(matlabbatch{3}.spm.stats.con.consess)
    
    if isfield(matlabbatch{3}.spm.stats.con.consess{c_con},'tcon')
        conname=matlabbatch{3}.spm.stats.con.consess{c_con}.tcon.name;
        contrastnames{c_con} = ['T_',conname];
        
    elseif isfield(matlabbatch{3}.spm.stats.con.consess{c_con},'fcon')
        conname=matlabbatch{3}.spm.stats.con.consess{c_con}.fcon.name;
        contrastnames{c_con} = ['F_',conname];
        
    end
    
end

%get files
subjdirs = dir(fullfile(padi.statspath, padi.subjcode));

%loop over subjects
for ss = 1:numel(subjdirs)
    
    % skip these subjects without HR
    if any(strcmp(subjdirs(ss).name,{'sub-003','sub-011'}))
        continue
    end
    
    %get contrast images
    con_nii = dir(fullfile(padi.statspath,subjdirs(ss).name,'con*.nii'));
    
    %loop over contrasts
    for c_con = 1:numel(con_nii)
        
        %make dir
        warning off; mkdir(fullfile(padi.savepath,contrastnames{c_con})); warning on;
        
        %copy file
        copyfile(...
            fullfile(padi.statspath,subjdirs(ss).name,con_nii(c_con).name),...
            fullfile(padi.savepath,contrastnames{c_con},...
            strcat(subjdirs(ss).name,'_',con_nii(c_con).name))...
            );        
    end
end