function [all_mis, all_phase_ids] = plotMis(mis, phasesI, nBinPhases, output_dir, titre)

all_mis = [];
all_phase_ids = [];

figure()
hold on
ctn_elements = 0;
for iBin=1:nBinPhases
    miBin = mis{iBin};
    phasesIds = phasesI{iBin};
    ctn_elements = ctn_elements + numel(phasesIds);
    
    % put into one vector for later
    % Add one value to Mi that corresponds to the ID of the fixed frame
    % taken for the registration
    % that way, the vectors are of equal lengths
    miBins_corr = [mean(miBin) squeeze(miBin)];
    all_mis = [all_mis, squeeze(miBins_corr)];
    all_phase_ids = [all_phase_ids, squeeze(phasesIds)];
        
    plot(phasesIds, miBins_corr, 'o')
    leg{iBin} = sprintf('Bin %d', iBin);
end
legend(leg);
axis([0 max(phasesIds, [], 'all') 0 1.15*max(all_mis, [], 'all')])
title(sprintf('mean :%.4f, std : %.4f', mean(all_mis), std(all_mis)))
savefig(fullfile(output_dir, [titre '.fig']))
exportgraphics(gcf, fullfile(output_dir, [titre '.png']))

end