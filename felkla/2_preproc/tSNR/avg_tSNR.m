%-----------------------------------------------------------------------
% avg_tSNR computes the mean tSNR images of a (number of) subject(s),
% across separate runs.
% It has only a single optional input 'ppts', containing
% the participant numbers belonging to the to-be-averaged images. 
% 'Ppts' Can be a single integer or a vector of integers. 
% If left empty, avg_tSNR computes the mean tSNR image for all subjects.
%
% Note that these images are in native space and need to be normalized
% before averaging across individuals.
%
% Felix Klaassen - April 2022
%-----------------------------------------------------------------------
function avg_tSNR(ppts)

if nargin == 0
    ppts = [0:12,14:66];
end

for s = 1:numel(ppts)
    % get subname
    if ppts(s) == 0
        SUBJNAME = 'sub-00x';
    elseif ppts(s) < 10
        SUBJNAME = ['sub-00' num2str(ppts(s))];
    elseif ppts(s) < 100
        SUBJNAME = ['sub-0' num2str(ppts(s))];
    else
        SUBJNAME = ['sub-' num2str(ppts(s))];
    end

    % create batch job
    matlabbatch{1}.spm.util.imcalc.input = {
        ['/project/3023009.03/stats/fMRI/tSNR/run-1/tSNR_' SUBJNAME '.nii,719']
        ['/project/3023009.03/stats/fMRI/tSNR/run-2/tSNR_' SUBJNAME '.nii,719']
        ['/project/3023009.03/stats/fMRI/tSNR/run-3/tSNR_' SUBJNAME '.nii,719']
        };
    matlabbatch{1}.spm.util.imcalc.output = [SUBJNAME '_tSNR'];
    matlabbatch{1}.spm.util.imcalc.outdir = {'/project/3023009.03/stats/fMRI/tSNR/mean_imgs'};
    matlabbatch{1}.spm.util.imcalc.expression = 'mean(X)';
    matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    matlabbatch{1}.spm.util.imcalc.options.dmtx = 1;
    matlabbatch{1}.spm.util.imcalc.options.mask = 0;
    matlabbatch{1}.spm.util.imcalc.options.interp = 1;
    matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

    % run batch
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch);

end
