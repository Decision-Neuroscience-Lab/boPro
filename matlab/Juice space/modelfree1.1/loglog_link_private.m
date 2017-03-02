function link = loglog_link_private( guessing, lapsing)
%
% THIS IS AN INTERNAL FUNCTION:  USE LOGLOG_LINK INSTEAD
%
% Log-log link in cell form for use with GLMFIT, GLMVAL and other Matlab
% GLM functions
%
% The guessing rate and lapsing rate are fixed, hence link is a function 
% of only one variable.  
%
% INPUT
%
% guessing - guessing rate
% lapsing - lapsing rate
%
% OUTPUT
%
% link - log-log link for use in all GLM functions; cell with 3 entries:  
%   	loglogFL - link function
%       loglogFD - derivative   
%   	loglogFI - inverse link
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROGRAM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SET LINK
link = cell(3,1);
link{1} = @(x) loglogFL( x, guessing, 1-lapsing);
link{2} = @(x) loglogFD( x, guessing, 1-lapsing);
link{3} = @(x) loglogFI( x, guessing, 1-lapsing);

% % % % % % % % % % % % % % % % % % 
% % % INTERNAL FUNCTIONS % % % % % 
% % % % % % % % % % % % % % % % % % 
%%%%%%%%%%%%%%%%%%
% LOGLOG WITH LIMITS

% link
function eta = loglogFL(mu,g,l)

mu = max(min(l-eps,mu),g+eps);
eta = -log(-log((mu-g)/(l-g)));

% derivative
function eta = loglogFD(mu,g,l)

mu = max(min(l-eps,mu),g+eps);
eta = -1./((mu-g).*log((mu-g)./(l-g)));

% inverse link
function mu = loglogFI(eta,g,l)

eta = max(-log(-log((eps)/(l-g))),eta);
eta = min(-log(-log(1-eps/(l-g))),eta);
mu = g + (l-g) * exp(-exp(-eta));