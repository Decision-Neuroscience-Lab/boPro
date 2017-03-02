load('imagine.csv')

min_delay = 10;
max_delay = 180;

ID = imagine(:,1);
imagine = imagine(:,2:end); % Remove IDs

x = [0 10/10 18/10 30/10 55/10 100/10 180/10]; % Objective time

subj_auc = zeros(length(imagine),1);

zth = zeros(length(imagine),numel(x));
for i = 1:length(imagine)
    zth(i,2:end) = imagine(i,:)/imagine(i,1);
end

for i = 1:length(zth);
    auc = zaub_auc(x,zth(i,:),min_delay,max_delay);
    subj_auc(i) = auc;
end
csvwrite('auc.csv',subj_auc)