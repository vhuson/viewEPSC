function [corrPeaks, corrValue] = viewCorrectAmplitude(peakIdx, method, settings, dataTrace, si)
%Correct peak amplitude based on Artifact,Baseline, or Paired pulse method
corrValue = zeros(size(peakIdx));
corrPeaks = corrValue;

switch method
    case 1 %Artifact correction
        [strts, stops] = viewGetArtifacts(dataTrace, si, settings);
        
        for i = 1:numel(peakIdx)
            corrValue(i) = max(dataTrace([strts(i),stops(i):peakIdx(i)]));
            corrPeaks(i) = dataTrace(peakIdx(i)) - corrValue(i);
        end
    case 2 %Baseline correction
        cellBaseline = viewCalculateBaseline(settings,dataTrace,si);
        for i = 1:numel(peakIdx)
            corrValue(i) = cellBaseline(peakIdx(i));
            corrPeaks(i) = dataTrace(peakIdx(i)) - corrValue(i);
        end
    case 3 %Paired pulse
        disp('Paired pulse correction not yet implemented');
        corrPeaks = [];
end

end