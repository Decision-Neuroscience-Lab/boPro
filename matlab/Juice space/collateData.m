juiceSpaceLoc = 'Q:\CODE\PROJECTS\TIMEJUICE\Juice Space\sessions';
cd(juiceSpaceLoc);
x = 1;

for p = [2:4, 6:7]
    if p == 2;
        filename = sprintf('%s\\%.0f_3*.mat', juiceSpaceLoc, p);
    else
        filename = sprintf('%s\\%.0f_4*.mat', juiceSpaceLoc, p);
    end
    loadname = dir(filename);
    load(loadname.name);
    
    m(x,1) = mean(data.trialLog(end).PM(1).threshold(end-9:end));
    m(x,2) = mean(data.trialLog(end).PM(2).threshold(end-9:end));
    m(x,3) = QuestMean(data.trialLog(end).q(1));
    m(x,4) = QuestMean(data.trialLog(end).q(2));
    
    s(x,1) = mean(data.trialLog(end).PM(1).slope(end-9:end));
    s(x,2) = mean(data.trialLog(end).PM(2).slope(end-9:end));
    
    se(x,1) = mean(data.trialLog(end).PM(1).seThreshold(end-9:end));
    se(x,2) = mean(data.trialLog(end).PM(2).seThreshold(end-9:end));
    
    x = 1 + x;
end

d.threshold = m;
d.slope = s;
d.se = se;
weber(:,1) = m(:,1)./0.5;
weber(:,2) = m(:,2)./3;
d.weber = weber;