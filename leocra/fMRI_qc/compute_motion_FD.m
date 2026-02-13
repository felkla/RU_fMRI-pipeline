function [FD, maxFD, percentOutliers] = compute_motion_FD(rp, FD_thresh)
    % rp: realignment params (Nvol x 6: translations + rotations)
    % FD_thresh: threshold in mm
    if nargin<2, FD_thresh=0.5; end

    R = [0 50 50]; % radius for rotations (mm)
    diffRp = [zeros(1,6); diff(rp)];
    rot = diffRp(:,4:6) * (pi/180) .* R;
    FD = sum(abs([diffRp(:,1:3) rot]),2);

    maxFD = max(FD);
    percentOutliers = 100*sum(FD>FD_thresh)/length(FD);
end