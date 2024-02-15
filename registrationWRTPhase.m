% This script creates a one-cycle video from a multiple OCT
% 
% The methodology of this repository was published in the article 
% "Denoising OCT videos based on temporal redundancy", by authors
% Emmanuelle Richer, Marissé Masis Solano, Farida Cheriet, Mark Lesk and
% Santiago Costantino, in Scientific Reports. 
% 
% This script will register images by bins of phase using the correlation 
% tilt technique by phase, then on averaged images. A final translation is
% done on the registered averaged images. 
% 
% Input arguments : 
%   list_ordered_bscans : structure containing the paths towards the OCT
%                         frames in a ordered fashion (synchronized with 
%                         the OCT timestamps and the pulse signal). This 
%                         structure needs to be organized as with the dir 
%                         function of matlab, with a .folder attribute and 
%                         .name attribute mandatory
%   oct_timestamps : array containing the oct timestamps
%   pulse : array containing the pulse amplitude information
%   timeSec : array containing the timestamps of the pulse signal in
%             seconds (must be same size as pulse variable)
%   timeMilliSec : array containing the timestamps of the pulse signal in
%                  milli seconds (must be same size as pulse variable)
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

%% Get phase corresponding to each timestamp

[phasesI, tAve] = getPhase(oct_timestamps, nBinPhases, numCycles, pulse, ...
                           timeSec, timeMilliSec);

%% Do tilt correlation registration by bin of phase

mis = computeTiltCorrelationRegistration(output_dir, transFolder, ...
                                         regFolder, ...
                                         list_ordered_bscans, phasesI, ...
                                         nBinPhases, kernelSize);

%% Plot Matttes Mutual Information all on one graph to assess image quality

[all_mis, all_phase_ids] = plotMis(mis, phasesI, nBinPhases, ...
                                   output_dir, 'all_MI');

%% Remove outliers

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

% Compute Mattes Mutual Information on average images
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

%% Create average video (mj2)

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

%% Do repeated video (mj2) for visualization purposes

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


