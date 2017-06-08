function [cellBaseline] = viewCalculateBaseline(baselineValue,dataTrace,si)

if nargin == 3
    xData = 0:si:(numel(dataTrace)-1)*si;
    yData = dataTrace;
else
    xData = dataTrace.XData;
    yData = dataTrace.YData;
end
%Get Values for interpolate
baseX = [baselineValue{2}(:,1);...
    baselineValue{2}(:,1)+baselineValue{2}(:,2)];
baseX = baseX(~isnan(baseX));

%Find points in trace
baseIdx = ones(size(baseX));
for i = 1:numel(baseIdx)
    idx = find(xData > baseX(i), 1, 'first');
    if isempty(idx); idx = numel(xData); end;
    baseIdx(i) = idx;
end

%Get Averages
baseX = [];
for i=1:numel(baseIdx)/2
    baseNums = sort([baseIdx(i),baseIdx(i+numel(baseIdx)/2)]);
    baseX(i) = round(mean(baseNums));
    baseY(i) = mean(yData(baseNums(1):baseNums(2)));
end

%Calculate Baseline
cellBaseline = interp1(baseX,baseY,1:numel(xData),baselineValue{1},'extrap');
end