function phasesI_corr = removeOutliers_getPhaseIds(regFolder, all_mis, all_phase_ids, phasesI, nBinPhases)

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