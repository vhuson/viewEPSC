function [ coords, features, gof ] = viewGetMiniParameters( miniTrace, si, bDouble,distance, preDistance,manualParameters )
%VIEWGETMINIPARAMETERS Calculate basic mini parameters through fitting
%   Correct peak location, find baseline (Baseline location from relative
%   to realX, find decay tau
if ~exist('manualParameters','var') || isempty(manualParameters)
    manualParameters = 0;
end
badFit = false;
%Get true minimum
peakOffset = round(min([0.002/si,distance/2,preDistance/2]));
% [realY,realX] = min(miniTrace(round(0.03/si)-peakOffset:...
%     round(0.03/si)+peakOffset));
%EXPERIMENTAL, USE findpeaks to get best peak in area
[y,x,pWidth,pAmp] = findpeaks(-miniTrace(round(0.03/si)-peakOffset:...
    round(0.03/si)+peakOffset), 'MinPeakProminence',2,'SortStr','descend');
if isempty(x) %No peaks fall back on original method
    [realY,realX] = min(miniTrace(round(0.03/si)-peakOffset:...
        round(0.03/si)+peakOffset));
else %Good just get the max amplitude one
    realX = x(1);
    realY = -y(1);
end
realX = realX-1-peakOffset;
% realX = 0;
% realY = miniTrace(300);
if 600+realX > numel(miniTrace)
    %window exceeds trace length make distance limiting step
    distance = numel(miniTrace)-(300+realX);
end

if manualParameters(1) == 1
    baseX = round(-(manualParameters(2)/si+realX));
    baseY = miniTrace(round(0.03/si+baseX));
else
    %Fit for baseline
    baseFit = fit((1:round(0.01/si))',miniTrace((round((0.02+si)/si):round(0.03/si))+realX),'poly6','Normalize','on');
    %plot(baseFit,(1:round(0.01/si))',miniTrace((round((0.02+si)/si):round(0.03/si))+realX));
    preBase = round(min([0.005/si,preDistance]));
    
    %Get baseline
    [baseY,baseX] = max(baseFit(round(0.01/si):-1:round(0.01/si)-preBase));
    [~,adjBaseX] = min(abs(miniTrace(...
        (round(0.03/si):-1:round(0.03/si)-baseX)+realX)-baseY));
    
    %Make sure there was something to be found, otherwise ignore adjustment
    if ~isempty(adjBaseX)
        baseX = 1-adjBaseX;
    else
        baseX = 1-baseX;
    end
    baseX = min([-1 baseX]);
end
%Fit for decay
decayLen = round(min([0.03/si distance-realX-0.001/si]));
if decayLen < 5 %Other event too close mark it
    decayLen = round(distance);
    badFit = true;
end

normMini = (miniTrace((round(0.03/si):round(0.03/si+decayLen-1))+realX)-baseY)/(realY-baseY);
[decayFit,gof,output] = fit((0:si:(decayLen-1)*si)',normMini,@(b,x)exp(b*x),...
    'StartPoint',-250,'Lower',-1500,'Upper',0,'DiffMinChange',1e-4,...
    'DiffMaxChange',1,'MaxIter',30);
% normMini = (miniTrace((round(0.03/si):round(0.03/si+decayLen-1))+realX)-baseY);
% if size((0:si:(decayLen-1)*si)',1) ~= size(normMini,1)
%     disp('shit')
% end
% [decayFit,gof,output] = fit((0:si:(decayLen-1)*si)',normMini,'exp1',...
%     'StartPoint',[(realY-baseY),-250],'Lower',[(realY-baseY)*1.1, -1500],...
%     'Upper',[(realY-baseY)*0.9, 0],'DiffMinChange',1e-4,...
%     'DiffMaxChange',1,'MaxIter',30);
%plot(decayFit,(0:si:(decayLen-1)*si)',normMini);

%calculate area
%Assume linear rise time from base to peak, and use decay fit for
%continued space
prePeak = interp1([baseX 0],[0, realY-baseY],[baseX:0]);
postPeak = decayFit(si:si:0.03-si+baseX*si)*(realY-baseY);
%plot([prePeak';postPeak]);
fArea = sum([prePeak';postPeak])*si;
sArea = sum(miniTrace((0.03/si:min([numel(miniTrace)-realX-baseX...
    ,0.06/si-1]))+realX+baseX)-baseY)*si;

decay50Y = prePeak(end)/2;
decay50X = log(decay50Y/(realY-baseY))/decayFit.b;
badFit = decay50X > 0.03 | badFit;
%Amplitude(pA); rise time (s), baseline(pA), decayTau (s), 50%X (s),
%50%Y(pA), fit area(pC), sum Area(pC), double?, bad fit
features = [realY-baseY, abs(baseX)*si, baseY, -1/decayFit.b ,decay50X,decay50Y fArea, sArea,bDouble,badFit];
coords = [realX realY];
gof = {gof,output}; %Goodness of fit from exp decay
end

