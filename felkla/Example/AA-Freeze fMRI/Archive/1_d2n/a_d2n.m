function a_d2n(SUBJNAME)
%--------------------------------------------------------------------------
%
% dicom to niftii convertion using SPM
%
%LdV2016
%--------------------------------------------------------------------------

% subject name
if nargin == 0
    SUBJNR = input('Please input subject number: ');
    if SUBJNR < 10
        SUBJNAME = ['sub-00' num2str(SUBJNR)];
    elseif SUBJNR < 100
        SUBJNAME = ['sub-0' num2str(SUBJNR)];
    else
        SUBJNAME = ['sub-' num2str(SUBJNR)];
    end
end

%path settings
mainpath='/home/affneu/felkla/AffectiveNeuroscience/D2A/2. fMRI project';
dicompath=fullfile(mainpath,'Data','raw',SUBJNAME,'ses-mri01');
datapath=fullfile(mainpath,'Data',SUBJNAME);

%conversion settings [runs over 3 types now, but more can be added]
%below it will search for the number of times each of these occurs in the
%dicom directory ['raw']
dcmname={...
    'cmrr_2p0iso_mb4_TR1500_run',...
    'field_map_2p0iso',...
    't1_mprage_sag_ipat2_1p0iso'};
niidir1={'func','struc','struc'};
niidir2={'task_','FM_','T1_'};

% Do not change anything below [only bugs]
%--------------------------------------------------------------------------

% Loop over dicom folders [in 'raw']
for c_dcm = 1:numel(dcmname)
    
    % Get directory where IMA/DICOM images are for this type
    dicomdirs=dir(fullfile(dicompath,['*',dcmname{c_dcm},'*']));
    
    % Loop over multiple tasks/runs/scans etc.
    for c_run = 1:numel(dicomdirs)
        
        % Covert dicoms to niftiis
        
        %paths
        currentpath=fullfile(dicompath,dicomdirs(c_run).name);
        
        %get dicom images
        dicomfiles=dir([currentpath,'/','*.IMA']);
        
        %load SPM job [does the dicom to niftii convertion]
        load f_d2n
        
        %output directory
        outputdir=fullfile(datapath,niidir1{c_dcm},[niidir2{c_dcm},num2str(c_run)]);
        mkdir(outputdir);
        
        %change input of the SPM BATCH
        matlabbatch{1}.spm.util.dicom.data = ...
            cellstr(strcat(fullfile(currentpath,'/',cellstr(char(dicomfiles.name)))));
        matlabbatch{1}.spm.util.dicom.outdir = ...
            cellstr(outputdir);
        
        %run the SPM BATCH
        spm_jobman('run',matlabbatch);
        
        % Change the default niftii name to subjectname
        
        %get niftiis
        newfiles=dir(fullfile(outputdir,'*.nii'));
        
        %loop over niftiis and change name
        for c_files=1:numel(newfiles)
            
            oldfile=fullfile(outputdir,newfiles(c_files).name);
            
            if c_files<10
                newfile=fullfile(outputdir,...
                    [char(SUBJNAME) '_000' num2str(c_files) '.nii']);
            elseif c_files<100
                newfile=fullfile(outputdir,...
                    [char(SUBJNAME) '_00' num2str(c_files) '.nii']);
            elseif c_files<1000
                newfile=fullfile(outputdir,...
                    [char(SUBJNAME) '_0' num2str(c_files) '.nii']);
            else
                newfile=fullfile(outputdir,...
                    [char(SUBJNAME) '_' num2str(c_files) '.nii']);
            end
            
            %by moving the file the name is changed
            movefile(oldfile,newfile)
            
        end %c_files
        
        clear matlabbatch
        
    end %c_run
    
end %c_dcm
