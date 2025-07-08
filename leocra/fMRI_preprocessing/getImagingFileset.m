function fileset = getImagingFileset(run_dir, files)
%GET_IMAGING_FILESET This function create SPM style file list for model specification
%
%   Input
%       run_dir: Run directory
%       files: File names
%
%   Output
%       fileset: Requested file list

% Get volumes
volumes = spm_vol([run_dir filesep files]);

% Initialize fileset
fileset = cell(1, size(volumes,1)); 

% Cycle over volumes to create fileset
for i = 1:size(volumes,1)
    fileset{i} = [run_dir filesep files ',' int2str(i)];
end
end

