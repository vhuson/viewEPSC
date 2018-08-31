function [ coords, features, targets ] = viewANNDetectMinis( ampThres,certThres,data,si,section )
%VIEWANNDETECTMINIS detects minis using an artificial neural network
%   Input Arguments: 
%   ampThres = detection threshold, cut of for amplitude of
%   peaks in pA;
%   certThres = certainty threshold, detection algorhitms certainty for
%   having found a mini between 0-100%
%   data = datatrace
%   si = sampling interval in seconds
%   section = two element vector with start and stop of to be detected
%   section of data trace

%Sanitize inputs
certThres = abs(certThres)/100;
if certThres < 0 || certThres > 1
    disp('Certainty threshold must be between 0 and 100');
    return;
end

start = round(section(1)/si);
stop = round(section(2)/si);
if start < 1
    start = 1;
elseif start > stop
    start = stop;
    stop = round(section(1)/si);
end
if stop > numel(data)
    stop = numel(data);
end
%detect peaks
if ampThres > 1
    [x,y,features] = roughMiniDetect(data(start:stop),1);
    checkPeaks = features(:,2) >= ampThres;
    
else
    [x,y,features] = roughMiniDetect(data(start:stop),ampThres);
    checkPeaks = true(size(x));
end
%Correct X for miniTrace position
x = x + (start-1);

targets=false(size(x,1),2);
%Get Peak data
peakData = viewGetMiniPeakData(data,x(checkPeaks),si);

%Generate targets
%Takes in sample rate reduced minis (window: 50ms 5kHz,250 samples);
%miniTargets = twoLayer250(peakData); %Good but often detects peaks
%more than once
%miniTargets = N161114_expanded15_5_autos(peakData);
miniTargets = N170303_unStrat(peakData);

miniTargets(isnan(miniTargets)) = false;
%miniTargets = logical(round(miniTargets));
% targets=false(size(miniTargets' ));
targets(~checkPeaks,2) = false;
targets(checkPeaks,1) = miniTargets(1,:)>certThres;
targets(checkPeaks,2) = miniTargets(2,:)>0.5;
%remove double labeled
targets(targets(:,1),2) = false;
%Set results
coords = [x,y];


end

