%% Plot tSNR images
% Felix Klaassen March 2025
% set parameters
subnr = 5;
% subjname = ['pilot0' num2str(subnr)];
subjname = ['sub-00' num2str(subnr)];

tsnrDir = '/home/klaassen/projects/telos/output/stats/tSNR';

%% plot average tSNR maps per run
subFiles = dir(fullfile(tsnrDir,subjname,'*.nii'));

for c_run = 1:numel(subFiles)
    
    %load data
    tSNRPath = fullfile(subFiles(c_run).folder,subFiles(c_run).name);
    data = spm_read_vols(spm_vol(tSNRPath));

    %which slices to plot
    zcoor = 25; %for axial; PAG
    xcoor = 60; %for sagittal;
    
    %other plotting parameters
    colors = {'parula','jet','gray'};
    color = colors{1};
    colorrange = [0 100]; % adjust range of the colorbar
    
    % sagittal slice
    figure;
    subplot(1,2,1)
    imagesc(squeeze(data(xcoor,:,:))'); colormap(color); colorbar; caxis(colorrange);
    set(gca,'YDir','normal');
    set(gca,'XDir','reverse');
    title('sagittal');

    % axial slice
    subplot(1,2,2)
    imagesc(data(:,:,zcoor)'); colormap(color); colorbar; caxis(colorrange);
    set(gca,'YDir','normal');
    set(gca,'XDir','reverse');
    title('axial');
    sgtitle([subjname ' run ' num2str(c_run)]);
    
    if ~exist(fullfile(tsnrDir,subjname,'plots'),'dir')
        mkdir(fullfile(tsnrDir,subjname,'plots'));
    end
    saveas(gcf,fullfile(tsnrDir,subjname,'plots',['run' num2str(c_run) '.png']))

end