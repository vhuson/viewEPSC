function [peakRaw, peakIdx, peakCorr, corrValue] = viewGetAmplitude2(dataNames,...
    artifactSettings, amplitudeSettings, baselineSettings, allPath, ephysDB)
%VIEWGETAMPLITUDE2 returns amplitudes from viewGUI setting files

%Single input corrections
if ~iscell(dataNames)
    dataNames = {dataNames};
end
if ~iscell(amplitudeSettings)
    amplitudeSettings = {amplitudeSettings};
end
if ~iscell(baselineSettings)
    baselineSettings = {baselineSettings};
end

%Make sure its in a cell for trace and another one for block
if ~iscell(artifactSettings)
    artifactSettings = {artifactSettings};
end
if ~iscell(artifactSettings{1})
    artifactSettings = {artifactSettings};
end

if ~iscell(allPath)
    allPath = {allPath};
end
if ~exist('ephysDB','var') || isempty(ephysDB)
    %Assume only one dataPath
    ephysDB = ones(size(dataNames));
end

peakCorr = cell(size(artifactSettings));
peakRaw = peakCorr;
peakIdx = peakCorr;
corrValue = peakCorr;

%loop over all files
for i = 1:numel(dataNames)
    if isempty(artifactSettings{i})
        %skip this one
        continue
    end
    %Get trace info
    artifactSetting = artifactSettings{i};
    filename = dataNames{i};
    dataPath = allPath{ephysDB(i)};
    %Get data and si
    fileData = retrieveEphys(filename,'data',dataPath); fileData = fileData{1}(:,1);
    fileSI = retrieveEphys(filename,'si',dataPath); fileSI = fileSI{1}*1e-6;
    
    for blck = 1:numel(artifactSetting)
        %Get artifact indexes (cell per block)
        artIdx = zeros(artifactSetting{blck}(2),2);
        [artIdx(:,1),artIdx(:,2)] = viewGetArtifacts(fileData,...
            fileSI,artifactSetting{blck});
        
        %Adjust to search from stop to next start
        lastFrame = artIdx(end,1) + (1/artifactSetting{blck}(3))/fileSI;
        if lastFrame > numel(fileData); lastFrame = numel(fileData); end;
        if lastFrame < artIdx(end,2); lastFrame = artIdx(end,2)+1; end;
        peakFrames = [artIdx(:,2),[artIdx(2:end,1); lastFrame]];
        
        peakRaw{i}(blck,:) = {zeros(size(peakFrames(:,1)))};
        peakIdx{i}(blck,:) = {zeros(size(peakFrames(:,1)))};
        
        
        %Calculate peaks
        for p =1:numel(peakRaw{i}{blck})
            [peakRaw{i}{blck}(p,1), peakIdx{i}{blck}(p,1)] =...
                min(fileData(peakFrames(p,1):peakFrames(p,2)));
            peakIdx{i}{blck}(p) = peakIdx{i}{blck}(p) + peakFrames(p,1) -1; %Correct to dataTrace
        end
        
        if nargout > 2 %Corrected values requested, requires more settings
            if isempty(amplitudeSettings{i}) ||...
                    numel(amplitudeSettings{i}) < blck
                %skip this one
                continue
            end
            
            
            %Calculate corrected peaks
            switch amplitudeSettings{i}(blck)
                case 1 %Artifact correction
                    %Initialize variables
                    peakCorr{i}(blck,:) = {zeros(size(peakFrames(:,1)))};
                    corrValue{i}(blck,:) = {zeros(size(peakFrames(:,1)))};
                    
                    for p = 1:numel(peakIdx{i}{blck})
                        corrValue{i}{blck}(p) = max(fileData(...
                            [artIdx(p,1),artIdx(p,2):peakIdx{i}{blck}(p)]));
                        peakCorr{i}{blck}(p) = peakRaw{i}{blck}(p)...
                            - corrValue{i}{blck}(p);
                    end
                case 2 %Baseline correction
                    %Initialize variables
                    peakCorr{i}(blck,:) = {zeros(size(peakFrames(:,1)))};
                    corrValue{i}(blck,:) = {zeros(size(peakFrames(:,1)))};
                    
                    cellBaseline = viewCalculateBaseline(...
                        baselineSettings{i},fileData,fileSI);
                    for p = 1:numel(peakIdx)
                        corrValue{i}{blck}(p) = cellBaseline(peakIdx{i}{blck}(p));
                        peakCorr{i}{blck}(p) = peakRaw{i}{blck}(p)...
                            - corrValue{i}{blck}(p);
                    end
                case 3 %Paired pulse
                    disp('Paired pulse correction not yet implemented');
            end
        end
        
    end
end
end