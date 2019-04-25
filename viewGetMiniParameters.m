function [ coords, features, gof ] = viewGetMiniParameters( miniTrace, si, bDouble,distance, preDistance,manualParameters )
%VIEWGETMINIPARAMETERS Calculate basic mini parameters through fitting
%   Correct peak location, find baseline (Baseline location from relative
%   to realX, find decay tau

%Hidden feature to extent baseline search (usefull for GABA minis)
GABAminis = false;


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
    distance = min([numel(miniTrace)-(300), distance]);
end

if manualParameters(1) == 1
    baseX = round(-(manualParameters(2)/si+realX));
    baseY = miniTrace(round(0.03/si+baseX));
else
    %Fit 10ms before peak for baseline
    baseFit = fit((1:round(0.01/si))',miniTrace((round((0.02+si)/si):round(0.03/si))+realX),'poly6','Normalize','on');
    %plot(baseFit,(1:round(0.01/si))',miniTrace((round((0.02+si)/si):round(0.03/si))+realX));
    if ~GABAminis
        %standard find baseline in the first 5ms before peak
        searchWindow = 0.005;
        preBase = round(min([searchWindow/si,preDistance]));
    else %Longer search window for baseline required 9ms?
        %using the maximum (10ms) is not recommended because fit often
        %starts with an extreme point before following the trace
        
        searchWindow = 0.009; %in seconds (max available from fit is 10ms)
        preBase = round(min([searchWindow/si,preDistance]));
    end
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
%Fit for decay (distance minus an estimate of next rise time)
decayLen = round(min([0.03/si distance-realX-0.001/si]));
if decayLen < 5 %Other event too close mark it
    decayLen = round(distance);
    badFit = true;
end

normMini = (miniTrace((round(0.03/si):round(0.03/si+decayLen-1))+realX)-baseY)/(realY-baseY);
% [decayFit,gof,output] = fit((0:si*10:(decayLen-1)*si)',normMini(1:10:end),@(b,x)exp(b*x),...
%     'StartPoint',-250,'Lower',-1500,'Upper',0,'DiffMinChange',1e-4,...
%     'DiffMaxChange',1,'MaxIter',30);
%Decimated
if decayLen > 20
    dec = floor(decayLen/20);
else
    dec =1;
end
[decayFit,gof,output] = fit((0:si*dec:(decayLen-1)*si)',normMini(1:dec:end),@(b,x)exp(b*x),...
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
% plot(decayFit,(0:si:(decayLen-1)*si)',normMini);
%Regression log fit
% normMini(normMini <= 0) = min(normMini(normMini > 0));
% decayFit2 = (0:si:(decayLen-1)*si)'\log(normMini);
% postPeak2 = exp(decayFit2*(si:si:0.03-si+baseX*si)')*(realY-baseY);

%calculate area
%Assume linear rise time from base to peak, and use decay fit for
%continued space
prePeak = interp1([baseX 0],[0, realY-baseY],[baseX:0]);
postPeak = decayFit(si:si:0.03-si+baseX*si)*(realY-baseY);
%plot([prePeak';postPeak]);
fArea = sum([prePeak';postPeak])*si;
sArea = sum(miniTrace((0.03/si:min([numel(miniTrace)-realX-baseX...
    ,0.06/si-1]))+realX+baseX)-baseY)*si;

% %Test new method
% postPeak2 = decayFit5(si:si:0.03-si+baseX*si)*(realY-baseY);
% fArea2 = sum([prePeak';postPeak2])*si;
% disp(['sArea:',num2str(sArea),' fArea:',num2str(fArea),' relDiff:',num2str(fArea2/fArea),' relDiff2:',num2str(fArea2/sArea)])

decay50Y = prePeak(end)/2;
decay50X = log(decay50Y/(realY-baseY))/decayFit.b;
badFit = decay50X > 0.03 | badFit;
%Amplitude(pA); rise time (s), baseline(pA), decayTau (s), 50%X (s),
%50%Y(pA), fit area(pC), sum Area(pC), double?, bad fit
features = [realY-baseY, abs(baseX)*si, baseY, -1/decayFit.b ,decay50X,decay50Y fArea, sArea,bDouble,badFit];
coords = [realX realY];
gof = {gof,output}; %Goodness of fit from exp decay
end

