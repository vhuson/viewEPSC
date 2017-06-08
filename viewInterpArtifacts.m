function [corrTrace, emptyTrace, predTrace] = viewInterpArtifacts(artifacts,tracedata)
%viewInterpArtifacts Calculates interpolation of artifacts, using the
%minimal width as the response start, extending pulses into the next
%artifact

if iscell(artifacts)
    minArt = cellfun(@(x) round(min(diff(x'))),artifacts);
else
    minArt = round(min(diff(artifacts')));
    artifacts = {artifacts};
end


%Correct trace
corrTrace = tracedata;
emptyTrace = tracedata;
predTrace = nan(size(tracedata));
for a = 1:numel(minArt)
    respStarts = artifacts{a}(:,1)+minArt(a);
    for i =1:numel(artifacts{a}(:,1))
        highPoint = max(corrTrace([artifacts{a}(i,1), artifacts{a}(i,2)]));
        emptyTrace(artifacts{a}(i,1)+1:artifacts{a}(i,2)-1) = NaN;
        corrTrace(artifacts{a}(i,1):respStarts(i)) = interp1([1;respStarts(i)-artifacts{a}(i,1)+1],...
            [corrTrace(artifacts{a}(i,1)), highPoint],(1:respStarts(i)-artifacts{a}(i,1)+1)');
        if artifacts{a}(i,2) > respStarts(i)
            corrTrace(respStarts(i):artifacts{a}(i,2)) = interp1([1;artifacts{a}(i,2)-respStarts(i)+1],...
                [highPoint,corrTrace( artifacts{a}(i,2))],(1:artifacts{a}(i,2)-respStarts(i)+1)');
        end
        predTrace(artifacts{a}(i,1):artifacts{a}(i,2)) = corrTrace(artifacts{a}(i,1):artifacts{a}(i,2));
    end
end
end