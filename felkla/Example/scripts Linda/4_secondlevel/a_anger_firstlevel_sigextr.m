function [extrdat]=a_anger_firstlevel_sigextr(subjname,sigextrinput)

%--------------------------------------------------------------------------
%
%
% extracts signal from all T maps within a single subject GLM
%
%LdV2015
%--------------------------------------------------------------------------

%get subjname
if ~exist('subjname')
    subjname=inputdlg('Which subject?');
end

% PARAMETERS
%--------------------------------------------------------------------------
%load paths
padi=i_anger_infofile(char(subjname));

%roinames
roinames=sigextrinput.roinames;

%stats path name
statsname=sigextrinput.statsname;

%which contrast images
numconimg=sigextrinput.numconimg;%contrast for each indv bin


% GET DATA
%--------------------------------------------------------------------------
%get the contrast maps for extraction
conimg=dir(fullfile(sigextrinput.statspath,char(subjname),'con*'));


%loop over roi's
a=1;
for c_roi=1:numel(roinames)
    
    clear roi_hdr roi_xyz
    
    %get hdr of roi
    roi_hdr=spm_vol(fullfile(padi.templates,roinames{c_roi}));
    
    %get roi coordinates
    roi_xyz = threeDfind(fullfile(padi.templates,roinames{c_roi}),1);
    
    
    %loop over contrast images
    for c_cmaps=numconimg;
        
        %get the beta map hdr
        con_hdr=spm_vol(fullfile(sigextrinput.statspath,char(subjname),conimg(c_cmaps).name));
        
        %get name of the contrast
        nroi=char(roinames(c_roi));
        extrdat.names{a}=strcat(nroi(1:end-4),'_',con_hdr.descrip);
        
        %check dimentions
        if abs(sum(sum(con_hdr.mat-roi_hdr.mat)))>0
            error('ROI and CONTRAST MAP are not in the same space!')
        end
        
        %get data out of ROI voxels
        extrdat.dat(:,a)=nanmean(spm_get_data(...
            fullfile(sigextrinput.statspath,char(subjname),conimg(c_cmaps).name),...
            roi_xyz));
        
        a=a+1;
    end %contrast maps

end %roi