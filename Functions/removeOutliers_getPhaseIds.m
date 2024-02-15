% This function computes a bimodal distribution on the Mattes Mutual
% Information metric computed on all the OCT images after registration. 
% If the bimodal distribution fits the data, the frames with the lowest
% metric will be detected as outliers.
%
% Input arguments :
%   regFolder: folder that will contain / contains the phasesIDs_corr.mat
%   all_mis : list of Mattes Mutual Information metric computed for all
%             images
%   all_phase_ids : list of all bin ids of all images
%   phasesI : cell array containing the id of the frames and their
%             corresponding bins. For example, phasesI{1} is a vector
%             containing the ids of all raw OCT scans corresponding to 
%             bin 1. This will be the output of the getPhase.m function.
%   nBinPhases: integer containing the number of bins used in the 
%               separation of the cardiac cycle. 
% 
% Return :
%   phasesI_corr : cell array containing the id of the frames and their
%                  corresponding bins after correction. For example, 
%                  phasesI_corr{1} is a vector containing the ids of all 
%                  raw OCT scans corresponding to bin 1. 
function phasesI_corr = removeOutliers_getPhaseIds(regFolder, all_mis, ...
                                                   all_phase_ids, ...
                                                   phasesI, nBinPhases)

if ~isfile(fullfile(regFolder, 'phasesIDs_corr.mat'))
    
    nbStd = 2;
    threshold = multithresh(all_mis);
    bad_ids = find(all_mis<threshold);
    good_ids = find(all_mis>=threshold);

    good_mis = all_mis(good_ids);
    bad_mis = all_mis(bad_ids);

    isBimodal = abs(median(good_mis) - median(bad_mis)) > ...
                (nbStd*abs(std(good_mis) + std(bad_mis)));

    if isBimodal
        new_ids = all_phase_ids(good_ids);
        new_mis = all_mis(good_ids);

        figure()
        plot(new_ids, new_mis, 'o')
        title('New mis after removing outliers')
        axis([0 max(new_ids, [], 'all') 0 1.15*max(new_mis, [], 'all')])
        savefig(fullfile(regFolder, 'mis_corr'))
        exportgraphics(gcf, fullfile(regFolder, 'mis_corr.png'))

        phasesI_corr = {};

        for iBin=1:nBinPhases
           % check if id is in ids to remove, if so remove it
           phasesIds = phasesI{iBin};

           idx = find(ismember(phasesIds, all_phase_ids(bad_ids)));

           % remove bad ids from that bin
           if numel(idx) > 0
               phasesIds(idx) = [];
           end

           phasesI_corr{iBin} = phasesIds;
        end
    else
        phasesI_corr = phasesI;
    end

    save(fullfile(regFolder, 'phasesIDs_corr.mat'), 'phasesI_corr')
else
    load(fullfile(regFolder, 'phasesIDs_corr.mat'), 'phasesI_corr')
end

end