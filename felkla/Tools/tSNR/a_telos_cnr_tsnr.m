function a_telos_cnr_tsnr(subjname)

%--------------------------------------------------------------------------
%
% Make tSNR image
%
%
%Linda de Voogd 2014
% edited by Felix Klaassen 2025
%--------------------------------------------------------------------------


% PARAMETERS
%--------------------------------------------------------------------------
%set paths
load('/home/klaassen/projects/telos/data/participantList.mat','participantList');
pptIdx = find(strcmp(participantList.subjNames,subjname));

projectpath = '/home/klaassen/projects/telos/'; %working directory (i.e., here)
if contains(participantList.subjNames{pptIdx},'pilot')
    datapath = '/projects/crunchie/telos/pilot/'; % nifti/bids data folder
else
    datapath = '/projects/crunchie/telos/'; % nifti/bids data folder
end
padi.func = [datapath ['data/PRISMA_' num2str(participantList.prismaNrs{pptIdx})]]; %location of niftis for this subject
padi.tasks = dir([padi.func '/ninEPI*']); %different runs of the task
padi.stats = [projectpath ['output/stats/tSNR/' subjname]]; %output folder

% RUN
%--------------------------------------------------------------------------

for c_run=1:numel(padi.tasks)

    %get images
    funcscans = cellstr(spm_select('List',fullfile(padi.func,padi.tasks(c_run).name),['^fPRISMA*.*\.nii']));
    funcscans = strcat(fullfile(padi.func,padi.tasks(c_run).name),'/',funcscans);

    %get the dimensions of a volume
    hdr = spm_vol(funcscans{1});
    dim = hdr.dim;
    
    %make mat
    echoMeans = zeros(dim(1),dim(2),dim(3));
    echoSTDs = zeros(dim(1),dim(2),dim(3));
    binmask = ones(dim(1),dim(2),dim(3));%start with all voxels
    allEchoes = zeros(dim(1),dim(2),dim(3),numel(funcscans));
       
    %loop over volumes
    clearvars temp
    for i = 1:numel(funcscans)
        
        %mean
        echoMeans(:,:,:) = ...
            echoMeans(:,:,:) + ...
            spm_read_vols(spm_vol(funcscans{i})) ...
            ./ numel(funcscans);
        %make mask for voxels having signal over all volumes
        temp(:,:,:)=...
            spm_read_vols(spm_vol(funcscans{i})) ...
            ./ numel(funcscans);
        binmask(:,:,:)=binmask(:,:,:) & ...
            round(temp(:,:,:));
        
        % create 4D matrix (x - y - z - time) to compute standard deviation
        allEchoes(:,:,:,i) = spm_read_vols(spm_vol(funcscans{i}));

        %old by LdV:
        %sequentially add up squared deviations divided by n-1
%         echoSTDs(:,:,:) = ...
%             echoSTDs(:,:,:) + ...
%             spm_read_vols(spm_vol(funcscans{i})) - ...
%             echoMeans(:,:,:) ./ numel(funcscans)-1;
            
    end
    
    %take standard deviation per voxel over time
    echoSTDs = std(allEchoes,[],4);
    
    %old by LdV
%     echoSTDs(:,:,:) = echoSTDs(:,:,:).^.5;

    %calculate tSNR and CNR
%     warning off;    %to avoid messages concerning divide by zero
    clearvars tSNR
    tSNR(:,:,:) = echoMeans(:,:,:)./echoSTDs(:,:,:);
%     warning on;
    
    %optional: plot a slice of the brain
    figure;imagesc(tSNR(:,:,24)); colormap('gray'); title(['tSNR for ' subjname ', run' num2str(c_run)]); colorbar
    
    %save them
    outDirectory = fullfile(padi.stats);
    if ~exist(outDirectory,'dir')
        mkdir(outDirectory);
    end
    hdr.dt = [64 0];
    hdr.fname = fullfile(outDirectory,['tSNR_',char(subjname),'_run' num2str(c_run) '.nii']);
    spm_write_vol(hdr,tSNR(:,:,:));

end