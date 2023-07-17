function registerAverageBinTiltTranslation(regFolder, regAveFolder, phasesI_corr, fileNames, nBinPhases, kernelSize)

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