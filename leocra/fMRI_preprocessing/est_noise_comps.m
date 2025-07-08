function est_noise_comps(run_filt, run_dir, noise_rois,prepobj)
%EST_NOISE_COMPS This function runs the estimation of the noise components 
% 
%   Input
%       run_filt: Run filenames filter
%       run_dir: Run directory 
%       realignment_prefix: Prefix indicating realignment
%
%   Output
%       None

warning off

% File selection
run_files = spm_select('List', run_dir, run_filt); 

% Create SPM style file list for model specification
fileset = getImagingFileset(run_dir, run_files);

clear matlabbatch

% General Parametersmatlabbatch{1}.spm.tools.physio.save_dir = {''};
matlabbatch{1}.spm.tools.physio.log_files.vendor = 'Siemens';
matlabbatch{1}.spm.tools.physio.log_files.cardiac = {''};
matlabbatch{1}.spm.tools.physio.log_files.respiration = {''};
matlabbatch{1}.spm.tools.physio.log_files.scan_timing = {''};
matlabbatch{1}.spm.tools.physio.log_files.sampling_interval = [];
matlabbatch{1}.spm.tools.physio.log_files.relative_start_acquisition = 0;
matlabbatch{1}.spm.tools.physio.log_files.align_scan = 'first';

% Scan Timing Parameters
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nslices = prepobj.nslices;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.NslicesPerBeat = [];
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.TR = prepobj.TR;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Ndummies = 0;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nscans = length(fileset);
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.onset_slice = ceil(prepobj.nslices/2);
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.time_slice_to_slice = [];
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nprep = [];
matlabbatch{1}.spm.tools.physio.scan_timing.sync.nominal = struct([]);

% Preprocessing
matlabbatch{1}.spm.tools.physio.preproc.cardiac.modality = 'ECG';
matlabbatch{1}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.min = 0.4;
matlabbatch{1}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.file = 'initial_cpulse_kRpeakfile.mat';
matlabbatch{1}.spm.tools.physio.preproc.cardiac.posthoc_cpulse_select.off = struct([]);

% Model Specification
matlabbatch{1}.spm.tools.physio.model.output_multiple_regressors = fullfile(run_dir,['tapas_regressors.txt']);
matlabbatch{1}.spm.tools.physio.model.output_physio = fullfile(run_dir,['physio.mat']);
matlabbatch{1}.spm.tools.physio.model.orthogonalise = 'all';
matlabbatch{1}.spm.tools.physio.model.censor_unreliable_recording_intervals = false;
matlabbatch{1}.spm.tools.physio.model.retroicor.no = struct([]);
matlabbatch{1}.spm.tools.physio.model.rvt.no = struct([]);
matlabbatch{1}.spm.tools.physio.model.hrv.no = struct([]);

% Noise Component Estimation
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.fmri_files = fileset';
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.roi_files = noise_rois;
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.force_coregister = {'no'};
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.thresholds = 0.1; %% parameters set here are corresponding to the recommendations in the CONN-toolbox documentation % parameters before 0.6
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.n_voxel_crop = 1;
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.n_components = 5; % parameter before 3 

% Movement Parameters
matlabbatch{1}.spm.tools.physio.model.movement.yes.file_realignment_parameters = {spm_select('fplist',run_dir,'^rp_.*\.txt$');};
matlabbatch{1}.spm.tools.physio.model.movement.yes.order = 24;
%matlabbatch{1}.spm.tools.physio.model.movement.yes.censoring_method = 'fd';
%matlabbatch{1}.spm.tools.physio.model.movement.yes.censoring_threshold = 0.5;

% Other Parameters
matlabbatch{1}.spm.tools.physio.model.other.no = struct([]);
%matlabbatch{1}.spm.tools.physio.model.other.yes.input_multiple_regressors = {spm_select('fplist',run_dir,'^rp_.*\.txt$');};

% Verbose Output Settings
matlabbatch{1}.spm.tools.physio.verbose.level = 0;
matlabbatch{1}.spm.tools.physio.verbose.fig_output_file = fullfile(run_dir,['tapas_output.jpg']);
matlabbatch{1}.spm.tools.physio.verbose.use_tabs = false;

% Run job
spm('defaults', 'FMRI');
inputs = cell(0, 1);
spm_jobman('serial', matlabbatch, '', inputs{:});
clear jobs

end
