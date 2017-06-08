function [peaks] = viewGetAmplitude(dataTrace, si, artifactSetting)
%Takes in trace, si and artifactsettings and returns peaks for all blocks
peaks = cell(size(artifactSetting,2),2);
for i = 1:numel(artifactSetting)
    %Get artifact indexes (cell per block)
    artIdx = zeros(artifactSetting{i}(2),2);
    [artIdx(:,1),artIdx(:,2)] = viewGetArtifacts(dataTrace,...
        si,artifactSetting{i});
    
    %Adjust to search from stop to next start
    lastFrame = artIdx(end,1) + (1/artifactSetting{i}(3))/si;
    if lastFrame > numel(dataTrace); lastFrame = numel(dataTrace); end;
    if lastFrame < artIdx(end,2); lastFrame = artIdx(end,2)+1; end;
    peakFrames = [artIdx(:,2),[artIdx(2:end,1); lastFrame]];
    peaks(i,:) = {zeros(size(peakFrames(:,1)))};
    
    %Calculate peaks
    for p =1:numel(peaks{i})
        [peaks{i,1}(p,1), peaks{i,2}(p,1)] = min(dataTrace(peakFrames(p,1):peakFrames(p,2)));
        peaks{i,2}(p) = peaks{i,2}(p) + peakFrames(p,1) -1; %Correct to dataTrace
    end
end
end