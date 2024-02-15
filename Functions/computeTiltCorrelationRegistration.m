% This function will register all images to their bin reference frame
% (first frame of every bin) using translation and tilt correlation
% approaches. The output of the tilt correlation is saved in a .txt file. 
%
% Input arguments:
%   output_dir : folder in which to save the tilt information .txt file
%   transFolder : folder that contains / will contain the OCT frames after
%                 translation
%   regFolder : folder that contains / will contain the OCT frames after
%               tilt registration
%   list_raw_scans : structure containing the filenames of the raw OCT 
%                    scans to register. This structure needs to be 
%                    organized as with the dir function of matlab, with a 
%                    .folder attribute and .name attribute mandatory
%   phasesI : cell array containing the id of the frames and their
%             corresponding bins. For example, phasesI{1} is a vector
%             containing the ids of all raw OCT scans corresponding to 
%             bin 1. This will be the output of the getPhase.m function. 
%   nBinPhases : integer containing the number of bins used in the 
%                separation of the cardiac cycle. 
%   kernelSize : kernel size (in pixels) for smoothing the images to help 
%                the translation registration operation. 
%
% Return : 
%   mis : Mattes Mutual Information metric assession the image quality and
%         the registration quality after registration of all frames of the 
%         video in a cell array. 
function mis = computeTiltCorrelationRegistration(output_dir, ...
                                                  transFolder, ...
                                                  regFolder, ...
                                                  list_raw_scans, ...
                                                  phasesI, ...
                                                  nBinPhases, kernelSize)

% create tilt info file
% open file and discard contents
fid = fopen(fullfile(regFolder, 'tilt_info.txt'), 'w');
fprintf(fid, 'phasesIds(i+1), p(1), p(2), angle \n');
fclose(fid);   

% iterate over bins of phase
mis = cell(nBinPhases, 1);
for iBin=1:nBinPhases
    fprintf('Bin : %d \n', iBin)

    % extract ids of frames in that bin
    phasesIds = phasesI{iBin};
    
    % take first frame in bins of phase as fixed frame    

    % open file by appending
    fid = fopen(fullfile(regFolder, 'tilt_info.txt'), 'a');
    fprintf(fid, 'Bin %d, fixed frame : %d \n', iBin, phasesIds(1));
    fclose(fid);            

    if ~isfile(fullfile(regFolder, list_raw_scans(phasesIds(1)).name))
        fixed = imread(fullfile(list_raw_scans(phasesIds(1)).folder, list_raw_scans(phasesIds(1)).name));
        imwrite(fixed, fullfile(transFolder, list_raw_scans(phasesIds(1)).name));
        imwrite(fixed, fullfile(regFolder, list_raw_scans(phasesIds(1)).name));
    else
        fixed = imread(fullfile(regFolder, list_raw_scans(phasesIds(1)).name));
    end
    
    fixedSmooth = medfilt2(fixed, kernelSize);
    Rfixed = imref2d(size(fixed));
    
    % register all frames in bin to that one
    mi = [];
    for i=1:numel(phasesIds)-1
        disp(i)

        % Translation
        if ~isfile(fullfile(transFolder, list_raw_scans(phasesIds(i+1)).name))
            
            fprintf('Working on : %s \n', list_raw_scans(phasesIds(i+1)).name);
            thisImage = imread(fullfile(list_raw_scans(phasesIds(i+1)).folder, list_raw_scans(phasesIds(i+1)).name));
            movingSmooth = medfilt2(thisImage, kernelSize);
            tformEstimate = imregcorr(movingSmooth, fixedSmooth, 'translation');
            movingReg = imwarp(thisImage, tformEstimate, 'OutputView', Rfixed);
            imwrite(movingReg, fullfile(transFolder, list_raw_scans(phasesIds(i+1)).name));
        else
            movingReg = imread(fullfile(transFolder, list_raw_scans(phasesIds(i+1)).name));
        end
        
        % tilt by correlation
        if ~isfile(fullfile(regFolder, list_raw_scans(phasesIds(i+1)).name))

            [newMoving_tilt, p, angle] = tiltImageByCorrelation(movingReg, fixed);
            imwrite(newMoving_tilt, fullfile(regFolder, list_raw_scans(phasesIds(i+1)).name)); 
            
            % save the line of the tilt 
            fid = fopen(fullfile(output_dir, 'tilt_info.txt'), 'a');
            fprintf(fid, '%d \t %.4f \t %.4f \t %.4f \n', phasesIds(i+1), p(1), p(2), angle);
            fclose(fid);
        else
            newMoving_tilt = imread(fullfile(regFolder, list_raw_scans(phasesIds(i+1)).name));
        end
        
        % Compute MMI 
        mi(i) = mattesMi(fixed, newMoving_tilt);
        
    end
    
    % Store MMI on all registered frames
    mis{iBin} = mi;
end

end