function D = deviance(r,m,pfit)
%
% Deviance for the fitted values of the psychometric function pfit.
%
% INPUT
% 
% r - number of successes
% m - number of trials 
% pfit - fitted values
%
% OUTPUT
% 
% D - deviance

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% PROGRAM

%%%% CHECK INPUT PARAMETERS

% Both arguments are mandatory
if (nargin<3)
    error('Check input. First 3 arguments are mandatory');
end

% adjustment to aviod degenerate values
r(r>=m) = r(r>=m)-.001;
r(r<=0) = .001;

pfit(pfit>=1) = 1-.001;
pfit(pfit<=0) = .001;   

% deviance
D = 2*sum((r .* log(r./(m.*pfit)) + (m - r) .* log((m - r)./(m - m.*pfit))));
