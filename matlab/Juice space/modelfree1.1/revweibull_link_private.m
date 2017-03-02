function link = revweibull_link_private(K,guessing,lapsing)
%
% THIS IS AN INTERNAL FUNCTION:  USE REVWEIBULL_LINK INSTEAD
%
% Reverse Weibull link in cell form for use with GLMFIT, GLMVAL and other Matlab
% GLM functions 
%
% The guessing rate and lapsing rate are fixed, and power parameter is set to be 
% equal K, hence link is a function of only one variable. 
%
% INPUT
% 
% K - power parameter for reverse Weibull link function
% guessing - guessing rate
% lapsing - lapsing rate
%
% OUTPUT
%
% link - reverse Weibull link for use in all GLM functions; cell with 3 entries:  
%   	revweibullkFL - link function
%       revweibullkFD - derivative   
%   	revweibullkFI - inverse link

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROGRAM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SET LINK
link = cell(3,1);
link{1} = @(x) revweibullkFL( x, guessing, 1-lapsing, K);
link{2} = @(x) revweibullkFD( x, guessing, 1-lapsing, K);
link{3} = @(x) revweibullkFI( x, guessing, 1-lapsing, K);

% % % % % % % % % % % % % % % % % % 
% % % INTERNAL FUNCTIONS % % % % % 
% % % % % % % % % % % % % % % % % % 

%%%%%%%%%%%%%%%%% LINK FUNCTION DEFINITIONS%%%%%%%%%%%%%%%%%%%%%%
% REVERSE WEIBULLK
function eta = revweibullkFL(mu,g,l,k)
mu = max(min(l-eps,mu),g+eps);
eta = -(-log((mu-g)/(l-g))).^(1/k);

function eta = revweibullkFD(mu,g,l,k)
mu = max(min(l-eps,mu),g+eps);
eta = 1./(k*(-log((mu-g)/(l-g))).^((k-1)/k).*(mu-g));

function mu = revweibullkFI(eta,g,l,k)
eta = max(-(-log(eps/(l-g))).^(1/k),eta);
eta = min(-(-log(1-eps/(l-g))).^(1/k),eta);
mu = g + (l-g) * exp(-(-eta).^k);