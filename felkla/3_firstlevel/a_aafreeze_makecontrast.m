function a_aafreeze_makecontrast(SUBJNR,DESIGN,CONTRNAME,CONTRVEC,TEST_flag)
%% Description
% A function to create extra first-level contrasts. This function can also
% be called for multiple subjects by using the wrapper run_makecontrast.m
%
% FelKla January 2021

%% Preparation
nRun = 3;

%get subjname
if ~exist('SUBJNR','var')
    SUBJNR = input('Please input subject number(s): ');
end

if SUBJNR < 10
    if SUBJNR == 0
        SUBJNAME = 'sub-00x';
    else
        SUBJNAME = ['sub-00' num2str(SUBJNR)];
    end
elseif SUBJNR < 100
    SUBJNAME = ['sub-0' num2str(SUBJNR)];
else
    SUBJNAME = ['sub-' num2str(SUBJNR)];
end

%get design
if ~exist('DESIGN','var')
    DESIGN = input('Please input design type (either ''factorial'' or ''parametric''): ');
end

%get type of test
if ~exist('TEST_flag','var')
    TEST_flag = 't'; % default is t-test
else
    %do nothing
end

%get contrast name and contrast weights
if ~exist('CONTRNAME','var')
    CONTRNAME = input('Please provide a name for the contrast: ');
end
if ~exist('CONTRVEC','var')
    CONTRVEC = input('Please provide a contrast weighting vector consisting of 0''s and 1''s: ');
end

%check compatibility of test with contrast weight-format
if strcmp(TEST_flag, 't') || strcmp(TEST_flag, 'T')
    assert(isvector(CONTRVEC),'For T-tests, contrasts should be of size 1xN or Nx1.');
elseif strcmp(TEST_flag, 'f') || strcmp(TEST_flag, 'F')
    assert(size(CONTRVEC,1)>1 & size(CONTRVEC,2)>1,'For F-tests, contrasts should be a matrix of size MxN such that M and N > 1.');
end

%% Load, edit, and then run batch job
%load default batch job
switch TEST_flag
    case {'t','T'}
        load('f_make_new_contrast_t.mat')
        
        %change parameters
        matlabbatch = struct_string_replace(matlabbatch,'sub-001',char(SUBJNAME));
        matlabbatch = struct_string_replace(matlabbatch,'DESIGN',char(DESIGN));
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = CONTRNAME;
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = CONTRVEC;
        
    case {'f','F'}
        load('f_make_new_contrast_F.mat')
        
        %change parameters
        matlabbatch = struct_string_replace(matlabbatch,'sub-001',char(SUBJNAME));
        matlabbatch = struct_string_replace(matlabbatch,'DESIGN',char(DESIGN));
        matlabbatch{1}.spm.stats.con.consess{1}.fcon.name = CONTRNAME;
        matlabbatch{1}.spm.stats.con.consess{1}.fcon.weights = CONTRVEC;
end

%run job
spm_jobman('run',matlabbatch);

end