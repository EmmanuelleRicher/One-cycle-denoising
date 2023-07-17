function [newMoving_tilt, p, angle] = tiltImageByCorrelation(movingTrans, fixed)

nS = 20;
largeur = size(fixed, 2);
x = 1:1:largeur;

nColumns = floor(largeur/nS);
shifts = zeros(1, nColumns);
xShifts = zeros(1, nColumns);

% compute correlation between every pair of a scans in both images
for i=1:nColumns
    
    [corr, lags] = xcorr(fixed(:, i*nS), movingTrans(:, i*nS));
    xShifts(i) = i*nS;
    % from correlation, find axial displacement of every extracted a
    % scan
    [~, idx] = max(corr);
    shifts(i) = -lags(idx);
end

% fit a line to estimate the axial displacement of every colomn
% don't take first two and last two because lateral shifts causes
% aberrations
p = polyfit(xShifts(3:end-2), shifts(3:end-2),1);

fittedShifts = p(2) + p(1)*x;

% pad every a scan according to axial displacement to create new
% image
newMoving_tilt = tiltImage(movingTrans, fittedShifts);

% extract angle from line
angle = atan2(fittedShifts(end), ceil(largeur/2));

% figure()
% plot(x, fittedShifts);
% title('Angle measured')
end