function [mean_tSNR, std_tSNR, tSNRmap] = compute_tSNR(data)
% COMPUTE_TSNR Robust temporal-SNR computation
%   data: X x Y x Z x T fMRI 4D array
%   mean_tSNR: mean of voxelwise tSNR across brain mask (scalar)
%   std_tSNR : std of voxelwise tSNR across brain mask (scalar)
%   tSNRmap  : voxelwise tSNR map (X x Y x Z) with invalid voxels = NaN
%
% Behavior:
% - ignores NaNs in time dimension
% - if number of timepoints < 2 returns NaNs
% - avoids division-by-zero by setting zero std voxels -> NaN
% - computes summary stats across a simple brain mask (threshold on mean)

    % basic checks
    if ndims(data) < 4
        error('compute_tSNR: input must be 4D (X x Y x Z x T).');
    end

    nt = size(data,4);
    if nt < 2
        warning('compute_tSNR: less than 2 timepoints — tSNR undefined. Returning NaNs.');
        tSNRmap = nan(size(data(:,:,:,1)));
        mean_tSNR = NaN;
        std_tSNR  = NaN;
        return;
    end

    % compute mean and std across time, ignoring NaNs
    tmean = nanmean(data, 4);
    tstd  = nanstd(data, 0, 4);   % normalized by (N-1)

    % avoid divide-by-zero: mark zero or non-finite std as NaN
    tstd(~isfinite(tstd) | tstd == 0) = NaN;

    % voxelwise tSNR
    tSNRmap = tmean ./ tstd;

    % set non-finite to NaN (covers Inf and -Inf)
    tSNRmap(~isfinite(tSNRmap)) = NaN;

    % create a simple brain mask to limit statistics to brain voxels
    % threshold: keep voxels with mean signal above 10% of global max
    thr = 0.10 * max(tmean(:), [], 'omitnan');
    brainMask = tmean > thr & isfinite(tSNRmap);

    if ~any(brainMask(:))
        % fallback: use any finite voxels
        brainMask = isfinite(tSNRmap);
    end

    % summary statistics across brain mask, ignoring NaNs
    mean_tSNR = nanmean(tSNRmap(brainMask));
    std_tSNR  = nanstd(tSNRmap(brainMask));
end
