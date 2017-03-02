corrstars <- function(data, repeats = 100, numTrials2Remove = 50){ 
  

# Random subset power analysis
require(data.table)
pVals <- array()
for (reps in seq(repeats)) {
  DT <- data.table(data) # Convert to data.table
  
  for (p in unique(data$id)) {
    DT <- DT[-sample(which(DT$id == p), numTrials2Remove)] # Drop n randomly sampled trials for each participant
  }
  
  # Analyse remaining dataset (use your own analysis)
  pdata = plm.data(data.frame(DT),index = c("id","trial"))
  fixed <- plm(response ~ delay + reward + lagReward + totalvolume + lagDelay + lagResponse, data = pdata, model = "within")
  temp <- coeftest(fixed, vcovHC)
  
  pVals <- rbind(pVals,temp[7:9,4]) # Concatenate p values into array
}

# Plot histogram of p values
require(ggplot2)
require(reshape2)
d <- melt(pVals)
ggplot(d,aes(x = value)) + 
  facet_wrap(~Var2, scales = "free_x") + 
  geom_histogram()
}