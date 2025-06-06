clear all;clc;
%--------------------------------------------------------------------------
%
%make average anatomical image of your subjects
%
%LdV 2014
%--------------------------------------------------------------------------


%get directory
subjpath='E:\projects\FCWML_fMRI\data';

%get subject directories
subjdirs=dir(subjpath);

%create list
subjlist=char(subjdirs.name);

%subjectnum
subjnum=0;

%loop over subjects
for c_ss=3:length(subjlist);%skip first 2 [. and ..]
    
    %CBI removes the '_' so make a second SUBJNAME
    SUBJNAMEcbi=erase(subjlist(c_ss,:),'_');
    
    % Normalize the T1
    load f_mri_fcwml_normalize_anat
    
    %replace subject code
    matlabbatch=struct_string_replace(matlabbatch,'MRI_FCWML001',subjlist(c_ss,:));
    matlabbatch=struct_string_replace(matlabbatch,'MRIFCWML001',SUBJNAMEcbi);
    
    %run with SPM
    spm_jobman('run',matlabbatch); clear matlabbatch

    %get anatomical scan
    anatdir=['sub-',SUBJNAMEcbi,'_ses-day2_acq-highres_run-02_T1w'];
    anatim=fullfile(subjpath,strcat(subjlist(c_ss,:)),...
        'ses-day2','anat',anatdir,strcat('w',subjlist(c_ss,:),'_0001.nii'));
    
    %check if it exists
    if exist(anatim);
        
        %get images
        hdr=spm_vol(anatim);
        dat=spm_read_vols(hdr);
        
        %when first subject make zero mat based on dimentions
        if ~exist('alldat');            
            alldat=zeros(hdr.dim);            
        end
        
        %add values
        alldat=alldat+dat;
        
        %keep track of subject number
        subjnum=subjnum+1;
        
    end
    
end

%make average
mean_anat=alldat./subjnum;

%write image
savepath=fullfile(subjpath,'mean_anat');
mkdir(savepath);
hdr.fname=fullfile(savepath,'mean_anat.nii');
spm_write_vol(hdr,mean_anat);

%reslice brainmask
im{1}=hdr.fname;
im{2}='E:\projects\FCWML_fMRI\data\mean_anat\brainmask_08.nii';

resflags = struct(...
      'mask',0,...  % don't mask anything
      'mean',0,...  % write mean image
      'which',2,... % write everything else
      'interp',1);  % linear interp

spm_reslice(im,resflags)

%get brainmask
cor=threeDfind(...
    'E:\projects\FCWML_fMRI\data\mean_anat\rbrainmask_08.nii',0.8);

%make bin mask
binmask=zeros(hdr.dim);%make zero matrix
for ivox=1:size(cor,2);%fill in
    binmask(cor(1,ivox),...
        cor(2,ivox),...
        cor(3,ivox)) = 1;
end

%skullstrip
mean_anat_skullstripped=binmask.*mean_anat;

%write image
hdr.fname=fullfile(savepath,'mean_anat_skullstripped.nii');
spm_write_vol(hdr,mean_anat_skullstripped);


