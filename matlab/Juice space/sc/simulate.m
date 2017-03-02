function resp = simulate(sc)
% simulates a response (very crude and ugly, I know)

% get the chance of a correct answer for these values
p = round(normcdf(sc.stairs(sc.current).stimval, sc.sim.mu, sc.sim.sg)* 100);

% fill up a vector of responses
pp = [repmat(0, 1, 100-p) repmat(1, 1, p)];

% randomly select one answer
resp = pp(ceil(100*rand(1,1)));