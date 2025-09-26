function percentOutliers = compute_global_signal_outliers(data4D, zThresh)
    % data4D: fMRI time series (X x Y x Z x T)
    % zThresh: SD threshold
    if nargin<2, zThresh=3; end
    
    globalSignal = squeeze(mean(mean(mean(data4D,1),2),3));
    zGS = (globalSignal - mean(globalSignal)) / std(globalSignal);
    
    outliers = abs(zGS) > zThresh;
    percentOutliers = 100*sum(outliers)/length(zGS);
end