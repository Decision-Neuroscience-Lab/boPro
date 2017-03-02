% Kubios HRV compilation

dataWelch = table;
dataAR = table;

for p = 1:52
    oldcd = cd('/Volumes/333-fbe/DATA/TIMEJUICE/PPP/physiological/Kubios HRV');
    filename = sprintf('PPP_%.0f_hrv.mat',p);
    load(filename);
    
    Res.HRV.Frequency.Welch = rmfield(Res.HRV.Frequency.Welch,{'F','PSD'});
    Res.HRV.Frequency.AR = rmfield(Res.HRV.Frequency.AR,{'F','PSD','PSD_comp','PSD_comp_pow'});
    
    dataWelch = cat(1,dataWelch,[array2table(p,'VariableNames',{'id'}),...
        struct2table(Res.HRV.Statistics),...
        struct2table(Res.HRV.Frequency.Welch),...
        array2table(Res.HRV.Frequency.EDR,'VariableNames',{'EDR'})]);
    
    dataAR = cat(1,dataAR,[array2table(p,'VariableNames',{'id'}),...
        struct2table(Res.HRV.Statistics),...
        struct2table(Res.HRV.Frequency.AR),...
        array2table(Res.HRV.Frequency.EDR,'VariableNames',{'EDR'})]);
end

writetable(dataAR,'/Users/Bowen/Documents/R/PPP/dataAR');
writetable(dataWelch,'/Users/Bowen/Documents/R/PPP/dataWelch');
