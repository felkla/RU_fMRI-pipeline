function a_aafreeze_RETROICOR_hera(padi)
%% Description
% Uses HERA to do artifact correction in heart rate data. Can be used in 
% preparation to create RETROICOR regressors for fMRI analysis.
%
% CREDIT: 
% Wrapper function by Felix Klaassen, 2021
% BAC & HERA scripts by Erno Hermans & Linda de Voogd
% See Glover, Li, & Ress (2000) for the original paper on RETROICOR


%% Open HERA
addpath([padi.main,filesep,'hera-master'])

hera

end
