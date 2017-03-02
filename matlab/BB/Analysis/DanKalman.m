function [likelihood, muHat_prior, sigmaHat_prior] = DanKalman(par, trialLog, counter)
% par(1) = lambda; this is the decay constant in the random walk
% par(2) = theta; this is the decay centre of the random walk
% par(3) = mu_pre0; this is the assumed initial payoff mean
% par(4) = sigma_pre0 ; this is the assumed initial payoff stdev
% par(5:end) = beta; this is the exploration/temperature parameter
%   subsequent values represent different participants
% trialLog is a structure containing, at a minimum, fields:
%   choice (which bandit was chosen, 1-4)
%   payout (the resulting payout)
% sigmaD is the gaussian noise of the diffusion process; it is held
%   constant to control for model degeneracy.
% sigma0 is the standard deviation of the gaussian distribution around the 
%   mean; also trying to hold it constant here.
   

choices = [trialLog.choice];
choices(isnan(choices)) = -1; % code missed responses
payouts = [trialLog.payout];
payouts(isnan(payouts)) = -1; % code missed responses


%% standard version
muHat_pre0 = par(1);
sigmaHat_pre0 = par(2);
betaHat = par(2 + counter);

sigma0Hat = 4;
sigmaDHat = 6;
% sigmaDHat = 2.8;
% lambdaHat = 0.9836;
lambdaHat = 1;
thetaHat = 50;
% muHat_pre0 = 85.7;
% sigmaHat_pre0 = 4.61;
% betaHat = 0.1;

%% exploration bonus version 1
% muHat_pre0 = par(1);
% sigmaHat_pre0 = par(2);
% phi = par(3);
% betaHat = par(3 + counter);
% 
% sigma0Hat = 4;
% sigmaDHat = 2.8;
% lambdaHat = 1;
% thetaHat = 50;
% % lambdaHat = 0.9836;
% % muHat_pre0 = 85.7;
% % sigmaHat_pre0 = 4.61;
% % betaHat = 0.1;

%% exploration bonus version 2
% muHat_pre0 = par(1);
% sigmaHat_pre0 = par(2);
% phi = par(3);
% betaHat = par(3 + counter);
% 
% sigma0Hat = 4;
% sigmaDHat = 2.8;
% % lambdaHat = 0.9836;
% % thetaHat = 50;
% % muHat_pre0 = 85.7;
% % sigmaHat_pre0 = 4.61;
% % betaHat = 0.1;

%% trade-off version
% muHat_pre0 = par(1);
% sigmaHat_pre0 = par(2);
% betaHat = par(3);
% gammaHat = par(3 + counter);
% 
% sigma0Hat = 4;
% sigmaDHat = 2.8;
% lambdaHat = 0.9836;
% thetaHat = 50;
% % muHat_pre0 = 85.7;
% % sigmaHat_pre0 = 4.61;
% % betaHat = 0.1;

%% Dan's Kalman Filter

% hardcoded parameters
I = 4; %number of bandits
T = 260; %number of trials

% initialise prior and posterior containers
muHat_prior = [zeros(I,T)];
muHat_posterior = [zeros(I,T)];
sigmaHat_prior = [zeros(I,T)];
sigmaHat_posterior = [zeros(I,T)];

% initialise independent gaussian oriors
muHat_prior(:,1) = muHat_pre0;
sigmaHat_prior(:,1) = sigmaHat_pre0;

for trial = 1:T % loop through trials
    
    % extract choice and payout for this trial
    choice = choices(trial);
    payout = payouts(trial);
    
    if choice == -1 || payout == -1
        continue
    end
    
    % work out posterior parameters for chosen bandit
    choice_mu_prior = muHat_prior(choice, trial); % get prior mean for choice
    choice_sigma_prior = sigmaHat_prior(choice, trial); % get prior sd for choice
    choice_variance_prior = choice_sigma_prior ^ 2; % calculate prior variance from sd    
    delta = payout - choice_mu_prior; % calculate prediction error for choice
    gain = (choice_variance_prior) / (choice_variance_prior + sigma0Hat^2); % calculate learning rate for choice
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
        muHat_prior(:,trial+1) = (lambdaHat * muHat_posterior(:,trial)) + ( (1 - lambdaHat) * thetaHat ); % calculate mu of next prior for all bandits
        nextPrior_variance = (lambdaHat^2) .* (sigmaHat_posterior(:,trial) .^ 2) + (sigmaDHat ^ 2); % calculate variance of next prior for all bandits
        
        % for exploration bonus version 2 and trade-off version
%         muHat_prior(:,trial+1) = muHat_posterior(:,trial);
%         nextPrior_variance = (sigmaHat_posterior(:,trial) .^ 2) + (sigmaDHat ^ 2); % calculate variance of next prior for all bandits
        
        sigmaHat_prior(:,trial+1) = sqrt(nextPrior_variance); % calculate stdev of next prior for all bandits

    end % end final trial if-loop
    

end % end trial loop



%% Choice rule
trial_choice_prob = zeros(I,T);

% calculate probability of each bandit at each step
for trial = 1:T
 
    
    trial_mu_priors = muHat_prior(:,trial);
    trial_sigma_priors= sigmaHat_prior(:,trial);
    
    %standard version
        trial_choice_prob(:,trial) = exp(betaHat .* trial_mu_priors) ./ sum(exp(betaHat .* trial_mu_priors ));

    %exploration bonus versions
%     trial_choice_prob(:,trial) = exp(betaHat .* (trial_mu_priors + phi * trial_sigma_priors) ) ./ sum(exp(betaHat .* (trial_mu_priors + phi * trial_sigma_priors)));
    
    % for tradeoff version
%     trial_choice_prob(:,trial) = exp(betaHat.* (gammaHat.*trial_mu_priors + (1 - gammaHat) .* trial_sigma_priors )) ./ sum(exp( betaHat .* (gammaHat.*trial_mu_priors + (1 - gammaHat) .* trial_sigma_priors )));

end %end trial loop

for trial = 1:T
    
    choice = choices(trial);
    if choice == -1
        choice_prob(trial) = NaN;
    else
        choice_prob(trial) = trial_choice_prob(choice, trial);
    end
            
end  % end trial loop

choice_prob(isnan(choice_prob)) = [];
likelihood = prod(choice_prob);

% correct for cases which have a smaller probability than matlab's minimum
% if likelihood == 0
%     likelihood = realmin;
% end
% log_likelihood = log(likelihood);

