sigmaDs = 3:0.25:20;
lambdas = 0.9:0.0025:1;

[sigmaDGrid, lambdaGrid] = meshgrid(sigmaDs,lambdas);
meanScore = [];
betaOut = [];
metric = [];
for i = 1:numel(sigmaDGrid)
    
   fprintf('Parameter set %.0f of %.0f\n',i,numel(sigmaDGrid)); 
   sigmaD = sigmaDGrid(i);
   lambda = lambdaGrid(i);
    
    [meanScore(i,:), betaOut(i,:)] = BlinkSimulator(lambda,sigmaD);
    
    X = [ones(size(betaOut(i,:)))' betaOut(i,:)'];
    Y = meanScore(i,:)';
    temp = regress(Y,X);
    metric(i) = temp(2);

end
metric = reshape(metric, size(sigmaDGrid));
h = imagesc(metric);
set(gca,'XTickLabel',sigmaDs(get(gca, 'XTick'))) 
set(gca,'YTickLabel',lambdas(get(gca, 'YTick'))) 

save('parameterGrid.mat', 'metric', 'sigmaDs', 'lambdas', 'betaOut', 'meanScore');