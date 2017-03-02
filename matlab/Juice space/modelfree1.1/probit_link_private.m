function link = probit_link_private( guessing, lapsing )
%
% THIS IS AN INTERNAL FUNCTION:  USE PROBIT_LINK INSTEAD
%
% Probit link in cell form for use with GLMFIT, GLMVAL and other Matlab
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
% link - probit link for use in all GLM functions; cell with 3 entries:  
%   	probitFL - link function
%       probitFD - derivative   
%   	probitFI - inverse link
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROGRAM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SET LINK
link = cell(3,1);
link{1} = @(x) probitFL( x, guessing, 1-lapsing);
link{2} = @(x) probitFD( x, guessing, 1-lapsing);
link{3} = @(x) probitFI( x, guessing, 1-lapsing);

% % % % % % % % % % % % % % % % % % 
% % % INTERNAL FUNCTIONS % % % % % 
% % % % % % % % % % % % % % % % % % 
%%%%%%%%%%%%%%%
% PROBIT WITH LIMITS

% link
function eta = probitFL(mu,g,l)

mu = max(min(l-eps,mu),g+eps);
eta = norminv((mu-g)./(l-g));

% derivative
function eta = probitFD(mu,g,l)

mu = max(min(l-eps,mu),g+eps);
eta = 1./normpdf(norminv((mu-g)/(l-g)))/(l-g);

% inverse link
function mu = probitFI(eta,g,l)

eta = max(norminv(eps./(l-g)),eta);
eta = min(-norminv(eps./(l-g)),eta);
mu = g + (l-g) * normcdf(eta);