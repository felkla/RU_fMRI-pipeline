function run_makecontrast(SUBS,DESIGN,CONTRNAME,CONTRVEC,TEST_flag)
% Wrapper function to make new first-level contrasts
%   INPUT
%   - SUBS. A vector indicating the subject numbers for which the contrast
%   is to be made.
%   - DESIGN. A string variable indicating for which design the contrast is
%   to be made. Either 'factorial' (default) or 'parametric'.
%   - CONTRNAME. A string variable indicating the name of the contrast.
%   - CONTRVEC. A vector specifying the weighting of the various regressors
%   in the design matrix.
%   - TEST_flag. A flag indicating whether to create a t or f-test. Accepts
%   as options both lower and uppercase versions of 't' and 'f'.

%% Settings
%set all input parameters
if ~exist('SUBS','var')
    SUBS = input('Please input subject number(s): ');
elseif ischar(SUBS)
    if strcmp(SUBS, 'all')
        SUBS = [0,1,2,4:10,12,14:18,20:28,30:34,36:49,51:53,55:63,65,66];
    end
end

if ~exist('DESIGN','var')
    DESIGN = 'factorial';
end
if ~exist('CONTRNAME','var')
    CONTRNAME = input('Please provide a name for the contrast: ');
end
if ~exist('TEST_flag','var')
    TEST_flag = 't'; % default is t-test
else
    %do nothing
end
if ~exist('CONTRVEC', 'var')
    CONTRVEC = input('Please provide a contrast weighting vector consisting of 0''s and 1''s: ');
end

%check compatibility of test with contrast weight-format
if strcmp(TEST_flag, 't') || strcmp(TEST_flag, 'T')
    assert(isvector(CONTRVEC),'For T-tests, contrasts should be of size 1xN or Nx1.');
elseif strcmp(TEST_flag, 'f') || strcmp(TEST_flag, 'F')
    assert(size(CONTRVEC,1)>1 & size(CONTRVEC,2)>1,'For F-tests, contrasts should be a matrix of size MxN such that M and N > 1.');
end

%general preparation
addpath 3_firstlevel
LoadSPM

%% Run batch script
%loop over subjects
for s = 1:numel(SUBS)
    a_aafreeze_makecontrast(SUBS(s),DESIGN,CONTRNAME,CONTRVEC,TEST_flag);
end
    
end

