function [ x,y, miniPars ] = roughMiniDetect( miniTrace, ampThres )
%roughMiniDetect Over detect peaks
%   Generates a lot of false positives for later correction by ANN
%% set parameters
data = -miniTrace; %Reverse peaks
%ampThres = 8; %Very necessary more reasonable value probably ~15
widthMin = 0; %No noticable difference so turned off
polSec = 6; %Polynomial points

%% detrend data
[p,~,mu] = polyfit((1:numel(data))',data,polSec);
f_y = polyval(p,(1:numel(data))',[],mu);

data = data - f_y;

%Filter data
framelength = 21; %was 31
 data = sgolayfilt(data, 3, framelength);
%% find peaks
[y,x,pWidth,pAmp] = findpeaks(data, 'MinPeakProminence',ampThres,...
    'MinPeakWidth',widthMin);

%Remove peak trends
%% Get Features
if ~isempty(x)
    minDist = diff(x);
    %Get closed neighbour (first and last don't get a choice)
    if numel(x) > 2
        minDist = [minDist(1);min([minDist(1:end-1),minDist(2:end)],[],2);minDist(end)];
    else
        minDist = [minDist; minDist];
    end
    riseTime = NaN(size(x));
    decay50 = riseTime;
    decay30 = riseTime;
    pArea = riseTime;
    for i = 1:numel(riseTime)
        x1 = x(i)-200;
        if x1>0 %Make sure beginning is visible
            %Find 30% point by substraction 70% prominence from data y value
            r30 = find(data(x1:x(i))>(y(i)-pAmp(i)*0.7));
            r90 = find(data(x1:x(i))>(y(i)-pAmp(i)*0.1));
            if ~isempty(r30) && ~isempty(r90) %Make sure entries were found
                riseTime(i) = r90(1)-r30(1);
            end
        end
        x2 = x(i)+300;
        if x2<numel(data) %Make sure end is visible
            d90 = find(data(x(i):x2)<(y(i)-pAmp(i)*0.1));
            d50 = find(data(x(i):x2)<(y(i)-pAmp(i)*0.5));
            d30 = find(data(x(i):x2)<(y(i)-pAmp(i)*0.7));
            if ~isempty(d50) && ~isempty(d90) %Make sure entries were found
                decay50(i) = d50(1)-d90(1);
                if ~isempty(d30)
                    decay30(i) = d30(1)-d50(1);
                end
            end
            if x1>0
                areaData = data(x1:x2)-min(data(x1:x2));
                pArea(i) = sum(areaData)*1e-4;
            end
        end
    end
    %Amp,Width,Rise30-90,Decay90-50,Decay50-30,Area
    miniPars = [minDist, pAmp,pWidth,riseTime,decay50,decay30,pArea];
    
    %Retrend y values and make negative
    y = -(y + f_y(x));
else
    miniPars = NaN(7,1);
end
end

