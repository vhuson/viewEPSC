function [ peakData ] = viewGetMiniPeakData( data, x ,si,miniSize )
%Returns mini shape
%   takes in data, and x peak coordinates and returns vector with mini information
%% detrend data
% polSec = 6;
% [p,~,mu] = polyfit((1:numel(data))',data,polSec);
% f_y = polyval(p,(1:numel(data))',[],mu);
% 
% data = data - f_y;
dataSize = 0.05/si;

if ~exist('miniSize','var')
    miniSize = 500;
else
    miniSize = round(abs(miniSize));
end

%Initialize peak info
peakData = zeros(miniSize,size(x,1));
%Get peak info
for j=1:size(x,1)
    x1 = x(j)-round((0.02-si)/si);
    x2 = x(j)+round(0.030/si);
    
    if x1<1
        miniData = [NaN(abs(x1)+1,1);data(1:x2)];
    elseif x2>numel(data)
        miniData = [data(x1:end);NaN(x2-numel(data),1)];
    else
        miniData = data(x1:x2);
    end
    %Normalize individual baseline
    miniBase = nanmean(miniData(1:20));
    if ~isnan(miniBase)
        miniData = miniData-miniBase;
    end
    
    %Conform to expected size
    if dataSize~=miniSize
        miniData = interp1(1:dataSize,...
            miniData,dataSize/miniSize:dataSize/miniSize:dataSize);
    end
    
    peakData(:,j) = miniData;
    
    
end
end

