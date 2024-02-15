% This function averages all images of same bin together and and registers
% the averaged images together to form a one-cycle movie
%
% Input arguments :
%   regFolder : folder containing the registered bin OCT images
%   regAveFolder : folder that will contain the averaged OCT images
%   phasesI_corr : cell array containing the id of the frames and their
%                  corresponding bins, after removal of outliers. For 
%                  example, phasesI_corr{1} is a vector containing the ids
%                  of all raw OCT scans corresponding to bin 1.
%   fileNames : structure containing the filenames of the registered OCT 
%               scans to average. This structure needs to be 
%               organized as with the dir function of matlab, with a 
%               .folder attribute and .name attribute mandatory
%   nBinPhases : integer containing the number of bins used in the 
%                separation of the cardiac cycle. 
%   kernelSize : kernel size (in pixels) for smoothing the images to help 
%                the translation registration operation. 
function registerAverageBinTiltTranslation(regFolder, regAveFolder, ...
                                           phasesI_corr, fileNames, ...
                                           nBinPhases, kernelSize)

% open file and discard contents
fid = fopen(fullfile(regAveFolder, 'tilt_info.txt'), 'w');
fprintf(fid, 'iBin, p(1), p(2), angle \n');

for iBin=1:nBinPhases

    if ~isfile(fullfile(regAveFolder, sprintf('aveBin%d.png', iBin)))
        
        % extract ids of frames in that bin
        phasesIds = phasesI_corr{iBin};

        % average all frames in bin
        frames = double(imread(fullfile(regFolder, fileNames(phasesIds(1)).name)))./255;
        for i=2:numel(phasesIds)
            % Translation
            thisImage = double(imread(fullfile(regFolder, fileNames(phasesIds(i)).name)))./255;

            frames = frames + thisImage;
        end
        aveFrame = frames./numel(phasesIds);
        imwrite(aveFrame, fullfile(regAveFolder, sprintf('aveBin%d_beforeReg.png', iBin)));
    
        % register average frame to first average frame
        if iBin > 1
            % Translate image before tilt 
            aveSmooth = medfilt2(aveFrame, kernelSize);
            tformEstimate = imregcorr(aveSmooth, fixedAveSmooth, 'translation');
            movingReg = imwarp(aveFrame, tformEstimate, 'OutputView', Rfixed);
            
            % Use tilt to register image
            [aveFrameReg, p, angle] = tiltImageByCorrelation(movingReg, fixedAve);
            fid = fopen(fullfile(regAveFolder, 'tilt_info.txt'), 'a');
            fprintf(fid, '%d \t %.4f \t %.4f \t %.4f \n', iBin, p(1), p(2), angle);
            fclose(fid);
            
            % Translate image laterally 
            tformEstimate = imregcorr(aveFrameReg, fixedAve, 'translation');
            aveFrameReg_trans = imwarp(aveFrameReg, tformEstimate, 'OutputView', Rfixed);
            
        else
            aveFrameReg_trans = aveFrame;
            fixedAveSmooth = medfilt2(aveFrame, kernelSize);
            fixedAve = aveFrameReg_trans;
            Rfixed = imref2d(size(fixedAve));
        end

        imwrite(aveFrameReg_trans, fullfile(regAveFolder, sprintf('aveBin%d.png', iBin)));
    end
end

end