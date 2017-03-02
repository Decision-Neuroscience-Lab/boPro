function link = weibull_link_private( K, guessing, lapsing )
%
% THIS IS AN INTERNAL FUNCTION:  USE WEIBULL_LINK INSTEAD
%
% Weibull link in cell form for use with GLMFIT, GLMVAL and other Matlab
% GLM functions 
%
% The guessing rate and lapsing rate are fixed, and power parameter is set to be 
% equal K, hence link is a function of only one variable. 
%
% INPUT
% 
% K - power parameter for Weibull link function
% guessing - guessing rate
% lapsing - lapsing rate
%
% OUTPUT
%
% link - Weibull link for use in all GLM functions; cell with 3 entries:  
%   	weibullkFL - link function
%       weibullkFD - derivative   
%   	weibullkFI - inverse link

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROGRAM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SET LINK
link = cell(3,1);
link{1} = @(x) weibullkFL( x, guessing, 1-lapsing, K);
link{2} = @(x) weibullkFD( x, guessing, 1-lapsing, K);
link{3} = @(x) weibullkFI( x, guessing, 1-lapsing, K);

% % % % % % % % % % % % % % % % % % 
% % % INTERNAL FUNCTIONS % % % % % 
% % % % % % % % % % % % % % % % % % 

%%%%%%%%%%%%%%%%% LINK FUNCTION DEFINITIONS%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
% WEIBULLK
function eta = weibullkFL(mu,g,l,k)
mu = max(min(l-eps,mu),g+eps);
eta = (-log((l-mu)./(l-g))).^(1/k);

function eta = weibullkFD(mu,g,l,k)
mu = max(min(l-eps,mu),g+eps);
eta = 1./(k*(-log((l-mu)./(l-g))).^((k-1)/k).*(l-mu));

function mu = weibullkFI(eta,g,l,k)
eta = max((-log(1-eps./(l-g))).^(1/k),eta);
eta = min((-log(eps./(l-g))).^(1/k),eta);
mu = g + (l-g) * (1 - exp(-eta.^k));