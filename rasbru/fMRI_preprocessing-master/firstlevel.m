function matlabbatch = firstlevel(cfg,prefix,results_dir,i_sub,mparams,physio,tapas_denoise,glmdenoise,is_loc)

% function matlabbatch = firstlevel(cfg,prefix,results_dir,onsname,i_sub,mparams,n_slices)

% cfg: passed from prepobj
% prefix: prefix of file (e.g. 'arf')
% results_dir: Subdirectory where results are written (e.g. 'myresult')
% i_sub: subject number
% mparams: should motion parameters be included (1 or 0)
% physio: should physiological parameters be included (1 or 0)
% glmdenoise: name of noise regressors or 0
% is_loc: if the data should be the one from the main experiment or the
% localizer 

mparams; % check if exists
physio;
glmdenoise;
tapas_denoise;

if sum(mparams+physio)>1 || (sum(mparams+physio)==1 && sum(glmdenoise) ~= 0)
    error('At the moment, only one of mparams, physio and glmdenoise can be chosen!')
end

sub_dir = fullfile(cfg.tgt_dir,i_sub);
ons_dir = fullfile(cfg.tgt_dir,i_sub,'onsets');

if ~isdir(results_dir), mkdir(results_dir), end

matlabbatch{1}.spm.stats.fmri_spec.dir = {results_dir};
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = cfg.TR;

ct = 0;
if is_loc 
    run_sel = cfg.run_sel{1};
else 
    run_sel = cfg.run_sel{2};
end 

for i_run = run_sel

    % get file names
    if is_loc
       run_dir = fullfile(sub_dir,sprintf('RUN_0%i%s',i_run,cfg.BIDS_fn_label{1}{1}));
    else
        run_dir = fullfile(sub_dir,sprintf('RUN_0%i%s',i_run,cfg.BIDS_fn_label{1}{2}));
    end 
    tmp = spm_select('FPList',run_dir,['^' prefix '.*\.(img|nii)$']);
    if isempty(tmp)
        error('No files found with prefix %s in %s',prefix,run_dir)
    end
    vols = spm_vol(tmp);
    files = cell(size(vols,1),1);
    for i = 1:size(vols,1)
        files{i} = [tmp(1,:) ',',num2str(i)];
    end
    
    ct = ct+1;
    matlabbatch{1}.spm.stats.fmri_spec.sess(ct).scans =files;
    
    if i_run == 1
        if ~exist('n_slices','var')
            hdr = spm_vol(files{1});
            n_slices = hdr.dim(3);
        end
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = n_slices;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = ceil(n_slices/2);
        
    end
    
    matlabbatch{1}.spm.stats.fmri_spec.sess(ct).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    if is_loc
        matlabbatch{1}.spm.stats.fmri_spec.sess(ct).multi = {fullfile(ons_dir,sprintf('%s%s_run-00%i_events.mat',i_sub,cfg.BIDS_fn_label{1}{1},i_run))};    
    else
        matlabbatch{1}.spm.stats.fmri_spec.sess(ct).multi = {fullfile(ons_dir,sprintf('%s%s_run-00%i_events.mat',i_sub,cfg.BIDS_fn_label{1}{2},i_run))};    
    end
    matlabbatch{1}.spm.stats.fmri_spec.sess(ct).regress = struct('name', {}, 'val', {});
    if mparams
        rp_name = spm_select('fplist',run_dir,'^rp_.*\.txt$');
        matlabbatch{1}.spm.stats.fmri_spec.sess(ct).multi_reg = {rp_name};
    elseif physio
        physio_path = fullfile(cfg.sub(i_sub).dir,'alldata','parameters');
        physio_name = fullfile(physio_path,sprintf('physioreg_run%02i.mat',i_run));
        if ~exist(physio_name,'file')
            error('No physio-logging found for subject %i and run %i',i_sub,i_run)
            physio_name = '';
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(ct).multi_reg = {physio_name};
    elseif tapas_denoise 
        tapas_name = fullfile(run_dir,'tapas_regressors.txt');
        matlabbatch{1}.spm.stats.fmri_spec.sess(ct).multi_reg = {tapas_name};
    elseif glmdenoise
        glmdenoise_path = fullfile(cfg.sub(i_sub).dir,'alldata','parameters');
        glmdenoise_name = fullfile(glmdenoise_path,glmdenoise,sprintf('noisereg_run%02i.mat',i_run));
        if ~exist(glmdenoise_name,'file')
            glmdenoise_name = fullfile(glmdenoise_path,sprintf('glmdenoise_%s_run%02i.mat',glmdenoise,i_run));
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(ct).multi_reg = {glmdenoise_name};
    else
        matlabbatch{1}.spm.stats.fmri_spec.sess(ct).multi_reg = {''};
    end
    matlabbatch{1}.spm.stats.fmri_spec.sess(ct).hpf = 128;
end

matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0]; %[1 0] for temporal derivatives, [0 0] without derivatives
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.6;
matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'none'; % alternative: 'AR(1)'; or 'none';

matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep;
matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tname = 'Select SPM.mat';
matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(1).value = 'mat';
matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(2).value = 'e';
matlabbatch{2}.spm.stats.fmri_est.spmmat(1).sname = 'fMRI model specification: SPM.mat File';
matlabbatch{2}.spm.stats.fmri_est.spmmat(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{2}.spm.stats.fmri_est.spmmat(1).src_output = substruct('.','spmmat');
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;