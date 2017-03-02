function [meanScore, betaOut] = BlinkSimulator(varargin)
    
    if nargin == 2
        par.lambda = varargin{1};
        par.sigmaD = varargin{2};
    else 
        par.lambda = 1;
        par.sigmaD = 6;
    end

    counter = 0;
    betas = [0:0.01:0.3];
%     betas = 0.05:0.01:0.25;
    for beta = betas
        
        counter = counter + 1;

        par.nSims = 50;
        par.sigma0 = 4;
%         par.sigmaD = 2.8;
%         par.lambda = 0.9836;
%         par.lambda = 0.9975;
%         par.sigmaD = 10;
        par.theta = 50;
        par.mu_pre0 = 85.7;
        par.sigma_pre0 = 4.61;
        par.beta = beta;
        par.nBandits = 4;
        par.nTrials = 260;
        par.pointBounds = [0 100];
    
           
        output = SimulatorLoop(par);
        meanScore(counter) = mean(output.score);
        betaOut(counter) = beta;
    end
    
    figure;
    plot(betaOut, meanScore);
    titleText = sprintf('Diffusion Sigma: %.1f, Decay Parameter: %.4f',par.sigmaD, par.lambda);
    title(titleText);
    xlabel('Beta Parameter')
    ylabel('Total Score')
    set(gca,'YLim',[1.2e4 2.1e4]);
end

function [output] = SimulatorLoop(par)
load('newWalks.mat');    

for sim = 1:par.nSims
% walks = BlinkyWalk(par);
I = par.nBandits;
T = par.nTrials;

% initialise prior, posterior and probability containers
muHat_prior = [zeros(I,T)];
muHat_posterior = [zeros(I,T)];
sigmaHat_prior = [zeros(I,T)];
sigmaHat_posterior = [zeros(I,T)];
trial_choice_prob = zeros(I,T);
choices = zeros(1,T);
payouts = zeros(1,T);

% initialise independent gaussian oriors
muHat_prior(:,1) = par.mu_pre0;
sigmaHat_prior(:,1) = par.sigma_pre0;

for trial = 1:T
    
    % calculate choice probabilities for current trial
    trial_mu_priors = muHat_prior(:,trial);
    trial_sigma_priors= sigmaHat_prior(:,trial);    
    trial_choice_prob(:,trial) = exp(par.beta .* trial_mu_priors) ./ sum(exp(par.beta .* trial_mu_priors ));
    
    % simulate a choice for the current trial
    bandit_cum_probs = cumsum(trial_choice_prob(:,trial));
    choiceRand = rand;
    choice = find(bandit_cum_probs > choiceRand, 1 );
    choices(trial) = choice;
    
    % get a feedback value for the choice
    choiceMean = walks(choice, trial);
    payout = SpinBandit(choiceMean, par.sigma0);
    payout = min(payout, max(par.pointBounds)); %ensure the payout is less than the maximum
    payout = max(payout, min(par.pointBounds)); %ensure the payout is more than the minimum
    payouts(trial) = payout;

     % work out posterior parameters for chosen bandit
    choice_mu_prior = muHat_prior(choice, trial); % get prior mean for choice
    choice_sigma_prior = sigmaHat_prior(choice, trial); % get prior sd for choice
    choice_variance_prior = choice_sigma_prior ^ 2; % calculate prior variance from sd    
    delta = payout - choice_mu_prior; % calculate prediction error for choice
    gain = (choice_variance_prior) / (choice_variance_prior + par.sigma0^2); % calculate learning rate for choice
    choice_mu_posterior = choice_mu_prior + gain * delta; % calculate mean of posterior distribution
    choice_variance_posterior = (1 - gain) * choice_variance_prior; % calculate variance of posterior distribution
    choice_sigma_posterior = sqrt(choice_variance_posterior); % calculate sd of posterior distribution from variance
    
    % assign posterior parameters to containers
    muHat_posterior(choice, trial) = choice_mu_posterior; % assign mu for chosen bandit
    sigmaHat_posterior(choice, trial) = choice_sigma_posterior; % assign sigma for chosen bandit
    notChoice = 1:I ~= choice;   
    muHat_posterior(notChoice,trial) = muHat_prior(notChoice, trial); % assign mu for unchosen bandits
    sigmaHat_posterior(notChoice, trial) = sigmaHat_prior(notChoice, trial); % assign sigma for unchosen bandits
    
    % calculate prior for subsequent trial
    if trial ~= T %i.e. only if we're not on the last trial
        
        % for standard version and exploration bonus version 1
        muHat_prior(:,trial+1) = (par.lambda * muHat_posterior(:,trial)) + ( (1 - par.lambda) * par.theta ); % calculate mu of next prior for all bandits
        nextPrior_variance = (par.lambda^2) .* (sigmaHat_posterior(:,trial) .^ 2) + (par.sigmaD ^ 2); % calculate variance of next prior for all bandits
        
        % for exploration bonus version 2 and trade-off version
%         muHat_prior(:,trial+1) = muHat_posterior(:,trial);
%         nextPrior_variance = (sigmaHat_posterior(:,trial) .^ 2) + (par.sigmaD ^ 2); % calculate variance of next prior for all bandits
        sigmaHat_prior(:,trial+1) = sqrt(nextPrior_variance); % calculate stdev of next prior for all bandits

    end % end final trial if-loop
end

output.choices(sim,:) = choices;
output.score(sim) = sum(payouts);


end


end


function [payout] = SpinBandit(banditMean, banditSD) 

unroundedPayout = banditMean + banditSD .* randn; %gaussian noise
%     unroundedPayout = banditMean + banditSD .* tan(pi * rand(1) - pi/2);   % noise from cauchy distribution (fat-tailed) 
payout = round(unroundedPayout);

end

