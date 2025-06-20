function a_aafreeze_cnr_tsnr(subjname)

%--------------------------------------------------------------------------
%
% Make tSNR image
%
%
%Linda de Voogd 2014, adapted by FelKla 2020
%--------------------------------------------------------------------------

%get subjname
if nargin == 0
    subjnr = input('Please input subject number: ');
    if subjnr < 10
        subjname = ['sub-00' num2str(subjnr)];
    elseif subjnr < 100
        subjname = ['sub-0' num2str(subjnr)];
    else
        subjname = ['sub-' num2str(subjnr)];
    end
end

if ~exist('subjnr','var')
    subjnr = str2double(subjname(end-2:end));
end

% PARAMETERS
%--------------------------------------------------------------------------
%load paths
padi=i_aafreeze_infofile(subjname);
if subjnr == padi.incompl_subs(1)
    padi.tasks = padi.tasks(1:2);
end

padi.stats= fullfile(padi.stats,'tSNR');
if ~exist(padi.stats,'dir')
    mkdir(padi.stats);
end

% RUN
%--------------------------------------------------------------------------

for c_tsk=1:numel(padi.tasks)
    
    %create folder
    if ~exist(fullfile(padi.stats, padi.tasks{c_tsk}),'dir')
        mkdir(fullfile(padi.stats, padi.tasks{c_tsk}));
    end 
    
    %get images
    funcscans=cellstr(spm_select('List',padi.func,['^ucsub.*', padi.tasks{c_tsk},'.*\.nii']));
    funcscans=strcat(padi.func,filesep,funcscans);
    
    %get the dimensions of a volume
    hdr = spm_vol(funcscans{1}); % Load the 4D file
    dim = hdr(1).dim; % 4D file, so we need to specifically index the first volume
    
    %make mat
    echoMeans= zeros(dim(1),dim(2),dim(3));
    echoSTDs= zeros(dim(1),dim(2),dim(3));
    binmask= ones(dim(1),dim(2),dim(3));%start with all voxels
       
    %loop over volumes
    for i=1:numel(hdr)
        
        %mean
        echoMeans(:,:,:) = ...
            echoMeans(:,:,:) + ...
            spm_read_vols(hdr(i)) ...
            ./ numel(hdr);
        
        %make mask for voxels having signal over all volumes
        temp(:,:,:)=...
            spm_read_vols(hdr(i)) ...
            ./ numel(hdr);
        binmask(:,:,:)=binmask(:,:,:) & ...
            round(temp(:,:,:));
        
        %sequentially add up squared deviations devided by n-1
        echoSTDs(:,:,:) = ...
            echoSTDs(:,:,:) + ...
            spm_read_vols(hdr(i)) - ...
            echoMeans(:,:,:) ./ numel(hdr)-1;
            
    end
    echoSTDs(:,:,:)=echoSTDs(:,:,:).^.5;
    
    %calculate tSNR and CNR
    warning off;    %to avoid messages concerning divide by zero
    tSNR(:,:,:) = echoMeans(:,:,:)./echoSTDs(:,:,:);
    warning on;
    
    % plot a single slice to check if there's signal
%     figure;imshow(tSNR(:,:,32)) % middle of the brain
    
    %save them
    hdr(end+1) = hdr(end);
    hdr(end).dt=[64 0];
    hdr(end).fname=fullfile(padi.stats,padi.tasks{c_tsk},['tSNR_',char(subjname),'.nii']);
    spm_write_vol(hdr(end),tSNR(:,:,:));

end