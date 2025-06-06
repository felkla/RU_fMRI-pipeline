%--------------------------------------------------------------------------
%RETROICORplus_calc
%
%Uses heart rate and respiration data to create nuisance regressors
%for physiological puslations. 
%Based on Glover et al 2000 MRM
%
%& based on UMCU scripts Bas Neggers / Matthijs Vink / Mariet van Buuren
%
%
%
%Input:
%Pulsedat: continuous recording of pulse data
%Respdat: continuous recording of respiration data
%TTLlines: line numbers in pulse/resp data for scanner TTLs
%Peaklines: line numbers in pulse data indicating heart beats
%sR: sample rate of pulse/resp data
%order: order of basis functions modeling cardiac/respiratory phase
%
%Out:
%CPR: cardiac phase regressors (2 (sin+cos) * order regressors)
%RPR: respiratory phase regressors (2 (sin+cos) * order regressors)
%NR: other nuisance regressors:
%1. HRF (6 s windowed)
%2. HRV (6 s windowed)
%3. Respiration (raw data averaged per TR)
%4. Respiratory amplitude (9 s windowed)
%5. Respiratory frequency (9 s windowed)
%6. RVT: Frequency times amplitude of respiration (average per TR)

%--------------------------------------------------------------------------

function [CPR,RPR,NR]=RETROICORplus_calc(TTLlines,Peaklines,Pulsedat,Respdat,sR,order)

%Settings
WinLen = 6; %Window length in sec for HRV calculation
WinLenResp = 9; %Window length in sec for respiration calculations

%Initialize empty vectors to fill up later
phasedat=zeros(size(Pulsedat));     %cardiac phase
ibidat=zeros(size(Pulsedat));       %ibi channel
HRV=zeros(size(Pulsedat));          %heart rate variability around each datapoint
HRF=zeros(size(Pulsedat));          %heart rate variability around each datapoint
respampdat=zeros(size(Pulsedat));   %respiration amplitude around each datapoint
respfreqdat=zeros(size(Pulsedat));  %respiration frequency around each datapoint
respphasedat = zeros(size(Pulsedat));%respiration phase
dRdt = zeros(size(Pulsedat));       %used for respiratory phase calculation

%First take all pulse peaks and calculate the phase at each time point
%Loop over pulses to calculate phase and IBI data
for i=2:length(Peaklines)
    phasedat(Peaklines(i-1):Peaklines(i)-1) = ...
        linspace(0,2*pi,diff(Peaklines(i-1:i)));
    ibidat(Peaklines(i-1):Peaklines(i)-1) = diff(Peaklines(i-1:i));
end

%Extrapolate start and end windows of ibidat
ibidat(1:Peaklines(1))= ibidat(Peaklines(1));
ibidat(Peaklines(end):end)=ibidat(Peaklines(end)-1);

%Calculate window averages for HR frequency (Hz) and HRV
WinSam=WinLen*sR;   %Window Length in samples
for i=Peaklines(1):WinSam:numel(phasedat)  %i=middle of window in samples
    WinSt=max(1,i-ceil(WinSam/2));
    WinEn=min(numel(HRV),i+ceil(WinSam/2));
    Winibi = ibidat(WinSt:WinEn);   %Winibi is the IBIchannel within the window
    Winibi(find(Winibi==0)) = [];   %remove zeros
    if mean(Winibi)>0
        HRF(i)= 1/(mean(Winibi)/sR); %HRF: mean heart rate freq in Hz
    else
        HRF(i)=0;  %or zero if there's no data
    end
    HRV(i)=var(Winibi./sR);  %Variance of heart period in sec within the window
end





%Loop over HRF datapoints to fill data in between
HRFlines = find(HRF>0);   %Lines in HRF that contain data
for i = 2:length(HRFlines),
    st = HRFlines(i-1);
    en = HRFlines(i);
    HRF(st:en) = HRF(st) + (HRF(en) - HRF(st)) * ((st:en) - st) / (en - st);
    HRV(st:en) = HRV(st) + (HRV(en) - HRV(st)) * ((st:en) - st) / (en - st);
end


WinSamResp = round(WinLenResp * sR);
for i = 1:WinSam:length(respampdat)  %Loop over respiration amplitude vector in window length steps
    st = max(1, i - ceil(WinSamResp / 2)); %start of respiration window
    en = min(length(respampdat), i + ceil(WinSamResp / 2)); %end of respiration window
    Winresp = Respdat(st:en);   %Take the data in the window
    r = corrcoef(Winresp, st:en);   %Perform a linear regression fit
    r = r(1, 2);
    rc = r * sqrt(var(Winresp)) / sqrt(var(st:en));
    lin_est = mean(Winresp) + rc * ((st:en) - mean(st:en)); 
    Winresp = Winresp - lin_est; %And detrend the respiration window
    fft0 = fft(Winresp);    %fourier transform respiration window
    fft0 = fft0(1:floor(length(fft0) / 2));
    [dum, fr0] = max(abs(fft0));
    respampdat0 = abs(fft0(fr0));               %Calculate respiration amplitude
    fr0 = (fr0 - 1) / (length(Winresp) / sR);   %Calculate respiration frequency
    respFreq0 = fr0;
    respampdat(i) = respampdat0;
    respfreqdat(i) = respFreq0;
end

%Loop over respiration frequency/amplitude datapoints to fill data in between
respamplines = find(respampdat>0);   %Lines in respampdat that contain data
for i = 2:length(respamplines),
    st = respamplines(i-1);
    en = respamplines(i);
    respampdat(st:en) = respampdat(st) + (respampdat(en) - respampdat(st)) * ((st:en) - st) / (en - st);
    respfreqdat(st:en) = respfreqdat(st) + (respfreqdat(en) - respfreqdat(st)) * ((st:en) - st) / (en - st);
end

RVT = respampdat .* respfreqdat; %frequency times amplitude of respiration


%respPhase = resp_phase(respvec, FS_Phys, MRI_scan_period);

%Calculate the respiration phase
sRespdat = Respdat + min(Respdat);
sRespdat = sRespdat / max(sRespdat); %Rescale the respiration

warning off
for i=1:sR:length(sRespdat) %Loop in 1 second steps over respiration data
    %n=i
    if i<=ceil(sR/2) || i>=floor(length(sRespdat)-ceil(sR/2)) %If smaller than half the samplerate or closer than that from end
        continue %then move on to next i
    end
    st=max(1,i-floor(sR/2));                %Start of 1 sec window
    en=min(length(sRespdat),i+floor(sR/2)); %End of 1 sec window
    x=(st:en)';
    y=sRespdat(x);
    X=[ones(size(x,1),1),x,x.*x];           %DM with constant, line, line^2
    fit_params = inv(X'*X)*(X')*y';          %Fit DM onto data
    dRdt(st:en) = 2 * fit_params(3) * (st:en) + fit_params(2); %Keep parameters
end

%Calculate the respiration phase per sample
[H, b] = hist(sRespdat, 100);
for n = 1:length(sRespdat)
    f = find(b <= sRespdat(n));
    temp = sum(H(f));
    respphasedat(n) = pi * sign(dRdt(n)) * temp / length(sRespdat);
end
respphasedat=respphasedat+pi;   %Scale it to 0 to 2pi like cardiac phase
warning on


%Calculate values per scan

%Loop over all TRs
for i=1:numel(TTLlines)-1
    
    st=TTLlines(i);             %Start of current TR
    en=TTLlines(i+1);           %End of current TR
    en=min([en,numel(Pulsedat)]); %Cut off if beyond end of recording
    mi=round(mean([st,en]));    %Middle of current TR
    
    %Get the cardiac phase in rad
    CP(i,1)=phasedat(mi);
    %Get the respiratory phase in rad
    RP(i,1)=respphasedat(mi);
    %Get the heart rate frequency average (6 s windowed)
    cdat=HRF(st:en);
    NR(i,1)=mean(cdat(cdat~=0)); %Do not include zeros
    %Get the heart rate variability (6 s windowed)
    cdat=HRV(st:en);
    NR(i,2)=mean(cdat(cdat~=0)); %Do not include zeros
    %Get the raw respiration average
    NR(i,3)=mean(Respdat(st:en));
    %Get the respiratory amplitude (9 s windowed)
    cdat=respampdat(st:en);
    NR(i,4)=mean(cdat(cdat~=0)); %Do not include zeros   
    %Get the Respiratory frequency (9 s windowed)
    cdat=respfreqdat(st:en);
    NR(i,5)=mean(cdat(cdat~=0)); %Do not include zeros 
    %Get the RVT / Frequency times amplitude of respiration (9 s windowed)
    cdat=RVT(st:en);
    NR(i,6)=mean(cdat(cdat~=0)); %Do not include zeros 
    
end

%Expand the cardiac and respiratory phase regressors to nth order
F=CP*[1:order];
CPR=[cos(F), sin(F)];
F=RP*[1:order];
RPR=[cos(F), sin(F)];








