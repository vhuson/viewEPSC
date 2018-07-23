function [pulseCharge,syncTrace,syncIdx] = viewGetResponseCharge(pulseStart,pWidths,...
    arts, cellBaseline, tracedata, si)

cellBaseline = cellBaseline(:);
%% mid artifact response start
minArt = round(min(diff(arts')));

respStarts = arts(:,1)+minArt;
%Correct trace
[corrTrace] = viewInterpArtifacts(arts,tracedata);

%Create Synchronous baseline
syncStartX = respStarts(1:end);
syncStopX = syncStartX+round(pWidths/si-1);

if numel(respStarts) > 1
    maxStopX = ([respStarts(2:end); respStarts(end)+diff(respStarts(1:2))])-1;
    if maxStopX(end) > size(corrTrace,1)-1
        maxStopX(end) = size(corrTrace,1)-1;
    end
else
    maxStopX = syncStopX;
end

syncStartY = corrTrace(syncStartX);
syncStopY = zeros(size(syncStartY));
for i = 1:numel(respStarts)
    syncStopY(i) = max(corrTrace([syncStartX(i), maxStopX(i)+1]));
end

syncTrace = interp1([syncStartX;maxStopX],[syncStartY;syncStopY],...
    (1:numel(tracedata))');
syncStopY = syncTrace(syncStopX);

traceFaults = find(syncTrace<corrTrace);
syncTrace(traceFaults) = corrTrace(traceFaults);
baseFaults = find(syncTrace>cellBaseline);
syncTrace(baseFaults) = cellBaseline(baseFaults);
% totalFaults =  find(corrTrace>cellBaseline);
% corrTrace(totalFaults) = cellBaseline(totalFaults);


%Calculate Sync/Async
sync = zeros(size(arts(:,1)));
async = sync;
total = sync;
for i = 1:numel(arts(:,1))
    sync(i) = -sum(corrTrace(syncStartX(i):syncStopX(i))...
        -syncTrace(syncStartX(i):syncStopX(i)));
    async(i) = -sum(syncTrace(syncStartX(i):syncStopX(i))...
        -cellBaseline(syncStartX(i):syncStopX(i)));
    total(i) = -sum(corrTrace(syncStartX(i):syncStopX(i))...
        -cellBaseline(syncStartX(i):syncStopX(i)));
end

pulseCharge = ([sync,async,total]).*si;
syncIdx = [[syncStartX;syncStopX],[syncStartY;syncStopY]];
end

% figure; hold on;
% plot(emptyTrace);
% plot(predTrace,'k--'); 
% scatter([syncStartX; syncStopX],[syncStartY; syncStopY]); 
% plot(syncTrace,'r--');
% plot(cellBaseline,'g:');
% hold off
% 
% %% Level Cuts, Sync width reduced
% %Correct trace
% corrTrace = tracedata;
% emptyTrace = tracedata;
% predTrace = nan(size(tracedata));
% for i =1:numel(strt)
%     highPoint = max(corrTrace([strt(i), stop(i)]));
%     emptyTrace(strt(i):stop(i)) = NaN;
%     corrTrace(strt(i):stop(i)) = interp1([1;stop(i)-strt(i)+1],...
%         [highPoint, highPoint],(1:stop(i)-strt(i)+1)');
%     predTrace(strt(i):stop(i)) = corrTrace(strt(i):stop(i));
% end
% %Create Synchronous baseline
% syncStartX = stop;
% syncStopX = ([strt(2:end); strt(end)+diff(strt(1:2))])-1;
% syncStartY = corrTrace(syncStartX);
% syncStopY = zeros(size(syncStartY));
% for i = 1:numel(stop)
%     syncStopY(i) = max(corrTrace([syncStartX(i), syncStopX(i)+1]));
% end
% 
% syncTrace = interp1([strt(1);syncStartX;syncStopX],...
%     [corrTrace(strt(1));syncStartY;syncStopY],...
%     (1:numel(tracedata))');
% 
% traceFaults = find(syncTrace<corrTrace);
% syncTrace(traceFaults) = corrTrace(traceFaults);
% baseFaults = find(syncTrace>cellBaseline);
% syncTrace(baseFaults) = cellBaseline(baseFaults);
% 
% %Calculate Sync/Async
% sync2 = zeros(size(strt));
% async2 = sync2;
% for i = 1:numel(strt)
%     sync2(i) = -sum(corrTrace(syncStartX(i):syncStopX(i))...
%         -syncTrace(syncStartX(i):syncStopX(i)));
%     async2(i) = -sum(syncTrace(strt(i):syncStopX(i))...
%         -cellBaseline(strt(i):syncStopX(i)));
% end
% 
% figure; hold on;
% plot(emptyTrace);
% plot(predTrace,'k--'); 
% scatter([syncStartX; syncStopX],[syncStartY; syncStopY]); 
% plot(syncTrace,'r--');
% %plot(test2,'g--');
% plot(cellBaseline,'g:');
% hold off
% 
% %% old
% %Create Synchronous cut off
% syncIdx = zeros(size(strt));
% syncTrace = nan(size(tracedata));
% %initialize
% [~,tempIdx] = max(corrTrace(arts(1,:)));
% syncIdx(1) = arts(1,tempIdx);
% i = 2;
% j = 2;
% while i <= numel(syncIdx)
%     [~,tempIdx] = max(corrTrace(arts(j,:)));
%     
%     %Check if line to previous is uninterupted
%     tempTrace = interp1(...
%         [1;arts(j,tempIdx)-syncIdx(i-1)+1],...
%         corrTrace([syncIdx(i-1),arts(j,tempIdx)]),...
%         (1:arts(j,tempIdx)-syncIdx(i-1)+1)');
%     traceFaults = find(tempTrace <...
%         corrTrace(syncIdx(i-1):arts(j,tempIdx)));
%     if isempty(traceFaults)
%         syncIdx(i) = arts(j,tempIdx);
%         syncTrace(syncIdx(i-1):arts(j,tempIdx)) = tempTrace;
%         i=i+1;
%         j=j+1;
%     else
%         syncIdx(end+1) = 0;
%         syncIdx(i) = traceFaults(1)+syncIdx(i-1)-1;
%         
%         syncTrace(syncIdx(i-1):syncIdx(i)) = interp1(...
%         [1;syncIdx(i)-syncIdx(i-1)+1],...
%         corrTrace([syncIdx(i-1),syncIdx(i)]),...
%         (1:syncIdx(i)-syncIdx(i-1)+1)');
%     
%         i=i+1;
%     end
%     
% end
% 
% %See if we need to start at the end of artifact
% if pulseStart == 1
%     respStart = stop;
% else
%     respStart = strt;
% end
% 
% %Loop pulses
% corrTrace = tracedata;
% for i =1:numel(strt)
%     corrTrace(strt(i):stop(i)) = interp1([1;stop(i)-strt(i)+1],...
%         corrTrace([strt(i), stop(i)]),(1:stop(i)-strt(i)+1)');
% end
% 
% for i = 1:numel(stop)
%     
% end
% end