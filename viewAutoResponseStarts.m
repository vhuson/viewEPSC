function [pulseStart] = viewAutoResponseStarts(artifactSetting,traceData,si)

block_n_pulses  = artifactSetting(2);

[strt, stop] = viewGetArtifacts(traceData, si, artifactSetting);

%Take a reasonable amount of pulses for run down
n_pulses = round(100*(1-(1/(1+exp(-(artifactSetting(3)/7.25-4))))))+2;
n_pulses(n_pulses > block_n_pulses) = block_n_pulses;

pulse_max = zeros(n_pulses,1);
for p = 1:n_pulses
    pulse_max(p) = traceData(strt(p)) < traceData(stop(p));
end
pulseStart = round(mean(pulse_max));

end