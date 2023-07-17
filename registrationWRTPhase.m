% This script creates a one-cycle video from a multiple OCT
% Register images by bins of phase using the correlation tilt technique
% Do tilt by phase, tilt on average images, then translation 
% Emmanuelle Richer
% Input arguments : 
%   list_ordered_bscans : structure containing the paths towards the OCT
%                         frames in a ordered fashion (synchronized with 
%                         the OCT timestamps and the pulse signal). This 
%                         structure needs to be organized as with the dir 
%                         function of matlab, with a .folder attribute and 
%                         .name attribute mandatory
%   oct_timestamps
%   pulse
%   timeSec
%   timeMilliSec
% July 2023
function registrationWRTPhase(list_ordered_bscans, ...
                              oct_timestamps, ...
                              pulse, timeSec, timeMilliSec, movieFolder)

addpath('./Functions')

%% parameters of the one cycle workflow

nBinPhases = 100;
numCycles = 1;
kernelSize = [40 40];

%% make necessary folders

output_dir = fullfile(movieFolder, 'outputs_one_cycle');
transFolder = fullfile(output_dir, 'translation');
regFolder = fullfile(output_dir, 'registration');

warning off
mkdir(output_dir)
mkdir(transFolder)
mkdir(regFolder)
warning on

%% get phase corresponding to each timestamps

[phasesI, tAve] = getPhase(oct_timestamps, nBinPhases, numCycles, pulse, ...
                           timeSec, timeMilliSec);

%% Do tilt correlation registration by bin of phase

mis = computeTiltCorrelationRegistration(output_dir, transFolder, ...
                                         regFolder, ...
                                         list_ordered_bscans, phasesI, ...
                                         nBinPhases, kernelSize);

%% plot mis all on one graph

[all_mis, all_phase_ids] = plotMis(mis, phasesI, nBinPhases, ...
                                   output_dir, 'all_MI');

%% remove outliers

phasesI_corr = removeOutliers_getPhaseIds(regFolder, all_mis, ...
                                          all_phase_ids, phasesI, ...
                                          nBinPhases);

[all_mis_corr, ~] = plotMis(mis, phasesI_corr, nBinPhases, ...
                            output_dir, 'all_MI_corr');

% save parameters
save(fullfile(output_dir, 'phases'), 'phasesI', 'tAve', 'phasesI_corr', ...
    'all_mis', 'all_mis_corr');

%% Registration of averaged bin frames
% for every bin, average registered frames and register it to a fixed 
% averaged frame

close all

regAveFolder = fullfile(output_dir, 'average');
warning off
mkdir(regAveFolder)
warning on

registerAverageBinTiltTranslation(regFolder, regAveFolder, phasesI_corr, ...
                                  list_ordered_bscans, nBinPhases, ...
                                  kernelSize)

% Compute MI on average images
if ~isfile(fullfile(regAveFolder, 'MI_ave.fig'))

    fixed = imread(fullfile(regAveFolder, sprintf('aveBin%d.png', 1)));
    mis = []; mis_uint8 = [];
    for iBin=2:nBinPhases
    
        im = imread(fullfile(regAveFolder, sprintf('aveBin%d.png', iBin)));
        mis_uint8(iBin-1) = mattesMi(fixed, uint8(im));
        mis(iBin-1) = mattesMi(fixed, im);
    end
    
    figure()
    subplot(121)
    plot(mis)
    xlabel('Averages frames')
    ylabel('MI on average frames')
    title('MIs on average movie');
    
    savefig(fullfile(regAveFolder, 'MI_ave'))
    exportgraphics(gcf, fullfile(regAveFolder, 'MI_ave.png'))

end

%% create average video (mj2)

if ~isfile(fullfile(regAveFolder, 'averageMovie.mj2'))
    writer = VideoWriter(fullfile(regAveFolder, 'averageMovie'), 'Archival');
    writer.LosslessCompression = true;
    writer.open();
    
    for iBin=1:nBinPhases
        aveFrameReg = imread(fullfile(regAveFolder, sprintf('aveBin%d.png', iBin)));
    
        writeVideo(writer, aveFrameReg);
    end
    close(writer);
    
end

%% do repeated video (mj2)

nRep = 10;
if ~isfile(fullfile(regAveFolder, sprintf('averageMovie_%d.mj2', nRep)))
    writer = VideoWriter(fullfile(regAveFolder, sprintf('averageMovie_%d', nRep)), 'Archival');
    writer.LosslessCompression = true;
    writer.FrameRate = 1/mode(diff(tAve));
    writer.open();
    for i = 1:nBinPhases*nRep
        disp(mod(i, nBinPhases)+1)
        im = imread(fullfile(regAveFolder, sprintf('aveBin%d.png', mod(i, nBinPhases)+1)));
        writer.writeVideo(im);
    end
    close(writer);
end

 
end


