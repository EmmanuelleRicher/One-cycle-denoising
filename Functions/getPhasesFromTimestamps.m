% rewrite function initially from the class AveragePulse into stand alone function
function [phase, binPhase] = getPhasesFromTimestamps(pulse, timePulseSec, timePulseMilliSec, numCycles, nBinPhases, t, ctn)

% extract peaks from timestampsPulse signal
% minimum distance for a peak in milliseconds
minDis = round(500 / mode(diff(timePulseMilliSec)));

% adding a small moving average to try to limit the bad peaks
[pks, locs] = findpeaks(movmean(pulse, 5), 'MinPeakDistance', minDis);

% add condition that peaks must be somewhat higher than median
% of signal
idx = find(pks > median(pulse));
pks = pks(idx);
locs = locs(idx);

if ctn == 1
    h = figure();
    plot(timePulseSec, pulse)
    hold on
    plot(timePulseSec(locs), pks, 'ro')
    title('Pulse signal with peaks for phase detection')
    close(h); 
end

phase = 0;
binPhase = 0;

% find closest inferior peak to target time value
% do difference and take last negative idx of difference and
% first positive idx of difference
I_pos = find((timePulseSec(locs) - t) > 0);
if numel(I_pos)==0
    % at the end of the signal, no more peak
    disp('End of signal, no more peak')
    phase = nan;
    binPhase = nan;
    return
end
imin = I_pos(1)-1;
if imin < 1
    disp(imin)
    imin = 1;
end

ipos = imin + numCycles;

% contingency for first frames of video where t is
% closer to 0 (which is often not detected as a peak)
% Don't consider those frames
if t < timePulseSec(locs(imin))
    fprintf('t : %.2f, timePulseSec(locs(min(I))) : %.2f \n', t, timePulseSec(locs(imin)))
   phase = nan;
   binPhase = nan;
   return
end

minPeak = timePulseSec(locs(imin));
% Take max peaks as numCycles further than the min starting peak
maxPeak = timePulseSec(locs(ipos));
% Between those peaks compute nBinPhases 
phasesT = linspace(minPeak, maxPeak, nBinPhases*numCycles);

if ctn < 100
   f = figure();
   plot(timePulseSec, pulse, 'k-')
   hold on
   plot(timePulseSec(locs), pks, 'bo')
   y = min(pulse):0.1:1.5*max(pulse);
   plot(t*ones(numel(y), 1),y);
   plot(minPeak, pulse(locs(imin)), 'ro')
   plot(maxPeak, pulse(locs(imin+numCycles)), 'ro')

   for p=phasesT
       plot(p*ones(numel(y), 1),y, 'c-');
   end
   
   close(f);
end

% return phase corresponding to bin where t is
[~, binPhase] = min(abs(phasesT - t));
phase = binPhase*2*pi/(nBinPhases*numCycles);

end