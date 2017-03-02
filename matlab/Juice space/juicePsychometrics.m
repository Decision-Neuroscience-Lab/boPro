function juicePsychometrics(x)

% disp('Hello, you are fitting the juice space data.')
% id = [];
% while isempty(id)
%     id = input('Enter participant ID: ');
% end


id = x;
 
% Load calibration file for participant
cd('Q:\CODE\PROJECTS\TIMEJUICE\Juice Space\data');
name = sprintf('%.0f_*', id);
loadname = dir(name);
load(loadname.name);

PrIC = @(B1,B0,p) -(log(p/(1-p)) + B0) / B1; % Inverted logistsic function

% Select variables and delete missed responses
X = [data.trialLog.anchor; data.trialLog.sample]';
Y = [data.trialLog.correct]';
i = Y == -1; % Locate and remove missing responses
Y(i) = [];
X(i,:) = [];
delta = X(:,2) - X(:,1);
Y = Y + 1; % Transpose correct/incorrect

% Generate psychometric function
[B,~,~] = mnrfit(delta,Y);
xx = linspace(min(delta),max(delta))';
yfit = mnrval(B,xx);
ip = (PrIC(B(2),B(1),0.75));
figure;
hold on
plot(ip,0.75,'kh');
plot(delta,Y-1,'o');
plot(delta(1:5),Y(1:5)-1,'rx');
plot(xx,yfit(:,2),'-','LineWidth',1);
xlabel('mL'); ylabel('Proportion correct');

savename = sprintf('Q:\\CODE\\PROJECTS\\TIMEJUICE\\Juice Space\\data\\id%.0f', id);
print(gcf,'-djpeg','-r150', savename);

% Psi
params = [alpha,beta,gamma,lambda];
StimLevels = linspace(min( x.trialLog(end).PM(1).x),max( x.trialLog(end).PM(1).x))';
pcorrect = PAL_CumulativeNormal(params, StimLevels);
plot(StimLevels,pcorrect);

% MOCS
[para LL exitflag] = PAL_PFML_Fit(stimlevels,accuracy*num_trials, num_trials*ones(size(stimlevels)), [parainit(1),parainit(2),gamma,parainit(3)], [1, 1, 0, 1], functionType, 'lapseLimits',[0, lambda_cap]);

return