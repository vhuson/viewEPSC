function [strts, stops] = viewGetArtifacts(tracedata, si, artifactSettings)
%viewGetArtifacts Finds start and stop indexes of artifacts in a trace
%   Takes in trace data, sample interval, and a vector containing: 
% 1: Start time (s); 2: number of pulse; 3: frequency (Hz); 4: width first
% pulse; 5: width last pulse; 6: 0/1 value to set auto adjusting to slope



%get the values from the preferences and convert to index
start_idx = artifactSettings(1)/si;
num_pulse   = artifactSettings(2);
interval    = (1/artifactSettings(3))/si;
firstWidth  = artifactSettings(4)/si;
lastWidth   = artifactSettings(5)/si;
autoAdjust   = logical(artifactSettings(6));


%%%%% we've collected all necessary data, let's start %%%%%

strts = zeros(sum(num_pulse), 1);

%get increment factor
incr_artf = (lastWidth - firstWidth)/(num_pulse-1);

%create the start indices for the artefacts
strts = ((0:num_pulse-1).*interval) + start_idx;

%creating increasing artifact vector
artf_vector = 0:num_pulse-1;
adapt_artf = round(artf_vector * incr_artf + firstWidth);

if isnan(adapt_artf) %No adaptation just the firstWidth (will only happen for 1 pulse)
    adapt_artf = repmat(firstWidth,size(strts));
end
stops = round(strts + adapt_artf);
strts = round(strts);

%Corrections
for i = 1:numel(stops)
    %move artifact to the drop
    if autoAdjust
        %move to after the drop
        if tracedata(stops(i)+1)>tracedata(stops(i))
            new_idx = find(diff(tracedata(stops(i):round(stops(i)+lastWidth*0.7)))<0);
            if ~isempty(new_idx)
                stops(i)= stops(i)+new_idx(1);
            end
            
            %move to before the drop
        elseif tracedata(stops(i)-1)>tracedata(stops(i))
            new_idx = find(diff(tracedata(round(stops(i)-adapt_artf(i)*0.7):stops(i)))>0);
            if ~isempty(new_idx)
                stops(i)= stops(i)-(round(adapt_artf(i)*0.7)-new_idx(end));
            end
        end
        %correct traces in which the artifact ends above baseline
        if tracedata(stops(i))>tracedata(strts(1))
            new_idx = find(tracedata(strts(i))>tracedata(stops(i):stops(i)+round(lastWidth)));
            if ~isempty(new_idx)
                stops(i)=stops(i)+new_idx(1);
            end
        end
    end
end

stops = stops(:);
strts = strts(:);


end

