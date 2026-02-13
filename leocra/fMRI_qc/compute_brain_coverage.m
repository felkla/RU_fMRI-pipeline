function coverage = compute_brain_coverage(meanVol)
    brainMask = meanVol > 0.2 * max(meanVol(:));
    coverage = 100 * sum(brainMask(:)) / numel(brainMask);
end