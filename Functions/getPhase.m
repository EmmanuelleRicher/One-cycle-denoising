function [phasesI, tAve] = getPhase(oct_timestamps, nBinPhases, numCycles, pulse, timePulseSec, timePulseMilliSec)

minDis = round(500 / mode(diff(timePulseMilliSec)));
[pks, locs] = findpeaks(pulse, 'MinPeakDistance', minDis);

meanPulseTime = mean(diff(timePulseSec(locs)));
tAve = linspace(0, meanPulseTime, nBinPhases);

phasesI = cell(nBinPhases, 1);
phases = [];
ts = [];

for ctn=1:numel(oct_timestamps)
    % current timestamp
    t = oct_timestamps(ctn);    
    
    % for each frame, compute phase
    [phase, binPhase] = getPhasesFromTimestamps(pulse, timePulseSec, timePulseMilliSec, numCycles, nBinPhases, t, ctn);
    
    % Accumulate in a vector the frames corresponding to the same bins
    % Add images to correct bin of phase 
    if ~isnan(phase)
       fprintf('ctn : %d, t : %.2f, phase : %.2f , binPhase : %d \n', ctn, t, phase, binPhase);
       ts(ctn) = t;
       phases(ctn) = phase;
       fprintf('binPhase : %d, size(phasesI) : (%d, %d), ctn : %d \n', binPhase, size(phasesI, 1), size(phasesI, 2), ctn)
       phasesI{binPhase} = [phasesI{binPhase} ctn]; 
    end
end
    

end