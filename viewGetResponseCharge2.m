function [pulseCharge,syncTrace,syncIdx] = viewGetResponseCharge2(dataNames,...
    chargeSettings, artifactSettings, baselineSettings, allPath, ephysDB)
%VIEWGETRESPONSECHARGE2 returns charge from viewGUI setting files

%Single input corrections
if ~iscell(dataNames)
    dataNames = {dataNames};
end
if ~iscell(chargeSettings)
    chargeSettings = {chargeSettings};
end
if ~iscell(baselineSettings{1})
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

%initialize
pulseCharge = cell(size(chargeSettings));
syncTrace = pulseCharge;
syncIdx = pulseCharge;

%Loop over all cells
for i = 1:numel(chargeSettings)
    %Get cell data
    if isempty(chargeSettings{i})
        %skip this one
        continue
    end
    %Get trace info
    artifactSetting = artifactSettings{i};
    chargeSetting = chargeSettings{i};
    baselineSetting = baselineSettings{i};
    
    filename = dataNames{i};
    dataPath = allPath{ephysDB(i)};
    %Get data and si
    fileData = retrieveEphys(filename,'data',dataPath); fileData = fileData{1}(:,1);
    fileSI = retrieveEphys(filename,'si',dataPath); fileSI = fileSI{1};
    if fileSI>1; fileSI = fileSI*1e-6; end;
    
    %Get baseline
    cellBaseline = viewCalculateBaseline(baselineSetting,fileData,fileSI);
    cellBaseline = cellBaseline(:);
    
    %Get pulseWidth
    pWidths = zeros(size(artifactSetting));
    p=1;
    while p <= numel(artifactSetting)
        if chargeSetting(2,p) >= 3 %Custom value
            pWidths(p) = chargeSetting(2,p)-3;
            %Check if not too large
            if pWidths(p) > 1/artifactSetting{p}(3)
                pWidths(p) = 1/artifactSetting{p}(3);
                chargeSetting(2,p) =  pWidths(p) + 3;
            end
        elseif chargeSetting(2,p) == 2
            allSettings = vertcat(artifactSetting{:});
            pWidths(:) = min(1./allSettings(:,3));
            p= numel(artifactSetting);
        elseif chargeSetting(2,p) == 1
            pWidths(p) = 1/artifactSetting{p}(3);
        end
        p=p+1;
    end
    
    %Loop over blcks
    pulseCharge{i} = cell(size(artifactSetting));
    syncTrace{i} = pulseCharge{i};
    syncIdx{i} = pulseCharge{i};
    for blck = 1:numel(artifactSetting)
        %Get Artifacts
        [strt,stop] = viewGetArtifacts(fileData,fileSI,artifactSetting{blck});
        arts = [strt,stop];
        
        %Get response starts at distance of minArt from art start
        minArt = round(min(diff(arts')));
        respStarts = arts(:,1)+minArt;
        
        %Correct trace
        [corrTrace] = viewInterpArtifacts(arts,fileData);
        
        %Create Synchronous baseline
        syncStartX = respStarts(1:end);
        pulseStopX = syncStartX+round(pWidths(blck)/fileSI-1);
        
        if numel(respStarts) > 1
            maxStopX = ([respStarts(2:end); respStarts(end)+diff(respStarts(1:2))])-1;
        else
            maxStopX = pulseStopX;
        end
        
        syncStartY = corrTrace(syncStartX);
        pulseStopY = zeros(size(syncStartY));
        for p = 1:numel(respStarts)
            pulseStopY(p) = max(corrTrace([syncStartX(p), maxStopX(p)+1]));
        end
        
        syncTrace{i}{blck} = interp1([syncStartX;maxStopX],[syncStartY;pulseStopY],...
            (1:numel(fileData))');
        pulseStopY = syncTrace{i}{blck}(pulseStopX);
        
        %Specify syncwidth
        if chargeSetting(1,blck) > 2 && chargeSetting(1,blck)-2 < pWidths(blck)
            %Get synchronous stops
            syncStopX = syncStartX+round((chargeSetting(1,blck)-2)/fileSI-1);
            
            %Get indices from sync to pulse stop
            asyncIdx = arrayfun(@(x,y) (x+1:y)',syncStopX,pulseStopX,...
                'UniformOutput',false);
            asyncIdx = vertcat(asyncIdx{:});
            
            %Set Sync to trace values
            syncTrace{i}{blck}(asyncIdx) = corrTrace(asyncIdx);
            
            syncStopY = syncTrace{i}{blck}(syncStopX);
        else %No valid sync width specified
            syncStopX = pulseStopX;
            syncStopY = pulseStopY;
        end
        
        traceFaults = find(syncTrace{i}{blck}<corrTrace);
        syncTrace{i}{blck}(traceFaults) = corrTrace(traceFaults);
        baseFaults = find(syncTrace{i}{blck}>cellBaseline);
        syncTrace{i}{blck}(baseFaults) = cellBaseline(baseFaults);
        % totalFaults =  find(corrTrace>cellBaseline);
        % corrTrace(totalFaults) = cellBaseline(totalFaults);
        
        
        %Calculate Sync/Async
        sync = zeros(size(arts(:,1)));
        async = sync;
        total = sync;
        for p = 1:numel(arts(:,1))
            sync(p) = -sum(corrTrace(syncStartX(p):pulseStopX(p))...
                -syncTrace{i}{blck}(syncStartX(p):pulseStopX(p)));
            async(p) = -sum(syncTrace{i}{blck}(syncStartX(p):pulseStopX(p))...
                -cellBaseline(syncStartX(p):pulseStopX(p)));
            total(p) = -sum(corrTrace(syncStartX(p):pulseStopX(p))...
                -cellBaseline(syncStartX(p):pulseStopX(p)));
        end
        
        pulseCharge{i}{blck} = ([sync,async,total]).*fileSI;
        syncIdx{i}{blck} = [[syncStartX;pulseStopX;syncStopX],[syncStartY;pulseStopY;syncStopY]];
    end
end

end