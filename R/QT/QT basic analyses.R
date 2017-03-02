# QT basic analysis
## Bowen J Fung, 2016

### Load data and required packages
trialData <- read.csv("~/Documents/R/QT/trialData.csv")
trialData$censor <- 1 - trialData$censor # In R, 1 is observed, 0 is censored

# Remove participants
trialData <- subset(trialData,!(id %in% c(32,34)))

# Subset data
#trialData <- subset(trialData, block > 4 & block < 9) # Only drink blocks
trialData <- subset(trialData, block <= 4 | block >= 9) # Only non-drink blocks

# Create data frame
source("/Users/Bowen/Documents/R/QT/getQT.R")
qtData <- getQT(trialData)
qtData <- within(qtData, {
  id <- factor(id)
  distribution <- factor(distribution)
  cond <- factor(cond)
})

### Distribution comparisons
require(coin)
# Proportion of quitting decisions
with(qtData, tapply(propQuit, distribution, median)) # Get means
with(qtData, tapply(propQuit, distribution, sd)) # Get SDs
with(qtData, tapply(propQuit, distribution, shapiro.test)) # Significance implies non-normality
wilcox.test(propQuit ~ distribution, data = qtData, paired = T) # Test differences
wilcoxsign_test(propQuit ~ distribution, data = qtData, distribution = "exact")

t.test(propQuit ~ distribution, data = qtData, paired = T) # Test differences

boxplot(propQuit ~ distribution, data = qtData, xlab = "Distribution", ylab = "Proportion of quitting decisions")

# Largest diff in M vs AUC comes from participants: 6, 8, 11, 14:19, 24, 

# Mean quitting time
with(qtData, tapply(M, distribution, mean)) # Get means
with(qtData, tapply(M, distribution, sd)) # Get SDs
with(qtData, tapply(M, distribution, shapiro.test)) # Significance implies non-normality
t.test(M ~ distribution, data = qtData, paired = T) # Test differences
wilcoxsign_test(M ~ distribution, data = qtData, distribution = "exact")

boxplot(M ~ distribution, data = qtData, xlab = "Distribution", ylab = "Mean quitting time")

# Experienced reward rate
with(qtData, tapply(rewardRate, distribution, mean)) # Get means
with(qtData, tapply(rewardRate, distribution, sd)) # Get SDs
with(qtData, tapply(rewardRate, distribution, shapiro.test)) # Significance implies non-normality
wilcox.test(rewardRate ~ distribution, data = qtData, paired = T) # Test differences
wilcoxsign_test(rewardRate ~ distribution, data = qtData, distribution = "exact")

t.test(rewardRate ~ distribution, data = qtData, paired = T) # Test differences

plot(qtData[qtData$distribution==2,"rewardRate"],qtData[qtData$distribution==2,"totalReward"])

# Adjusted performance
with(qtData, tapply(adjPerf, distribution, mean)) # Get means
with(qtData, tapply(adjPerf, distribution, sd)) # Get SDs
with(qtData, tapply(adjPerf, distribution, shapiro.test)) # Significance implies non-normality
wilcox.test(adjPerf ~ distribution, data = qtData, paired = T) # Test differences

t.test(adjPerf ~ distribution, data = qtData, paired = T) # Test differences

# Earnings
with(qtData, tapply(earnings, distribution, mean)) # Get means
with(qtData, tapply(earnings, distribution, sd)) # Get SDs
with(qtData, tapply(earnings, distribution, shapiro.test)) # Significance implies non-normality
wilcox.test(earnings ~ distribution, data = qtData, paired = T) # Test differences
wilcoxsign_test(earnings ~ distribution, data = qtData, distribution = "exact")

t.test(earnings ~ distribution, data = qtData, paired = T) # Test differences

# Full test for differences in earnings
require(ez)
reward <- aggregate(totalReward ~ id + distribution + block + drink, 
                    data = trialData[, c("id","distribution","block","totalReward","drink")],
                    FUN = function(x) c(MAX = max(x)))
# Add condition variable
reward[reward$id < 26,"cond"] <- 1 # Gluc
reward[reward$id >= 26,"cond"] <- 2 # Water
# Refactor
reward$drink <- factor(reward$drink)
reward$cond <- factor(reward$cond)

# For distributions
ezANOVA(data = reward, dv = totalReward, wid = id, 
        within = .(distribution),
        type = 3, detailed = T, return_aov = F)
ezPlot(x = drink, data = subset(reward, distribution == 1), 
       dv = totalReward, wid = id, split = cond,
       within = .(drink), between = .(cond), 
       type = 3)

# For treatments and drinking
ezANOVA(data = subset(reward, distribution == 1), dv = totalReward, wid = id, 
        within = .(drink), between = .(cond),
        type = 3, detailed = T, return_aov = F)
ezPlot(x = drink, data = subset(reward, distribution == 1), 
       dv = totalReward, wid = id, split = cond,
       within = .(drink), between = .(cond), 
       type = 3)

ezANOVA(data = subset(reward, distribution == 2), dv = totalReward, wid = id, 
        within = .(drink), between = .(cond),
        type = 3, detailed = T, return_aov = F)
ezPlot(x = drink, data = subset(reward, distribution == 2), 
       dv = totalReward, wid = id, split = cond,
       within = .(drink), between = .(cond), 
       type = 3)

# Post-hoc tests
t.test(totalReward ~ drink, 
       data = subset(reward, distribution == 2 & cond == 2), paired = F) # Test differences

# Let's make these earnings results really clear

# AUC
with(qtData, tapply(AUC, distribution, median)) # Get means
with(qtData, tapply(AUC, distribution, sd)) # Get SDs
with(qtData, tapply(AUC, distribution, shapiro.test)) # Significance implies non-normality
wilcox.test(AUC ~ distribution, data = qtData, paired = T) # Test differences
wilcoxsign_test(AUC ~ distribution, data = qtData, distribution = "exact")

t.test(AUC ~ distribution, data = qtData, paired = T) # Test differences

# Differences in proportion of quitting decisions across treatments
with(subset(qtData, distribution == 1), tapply(propQuit, cond, shapiro.test)) # Significance implies non-normality
t.test(propQuit ~ cond, data = subset(qtData, distribution == 1), paired = F) # Test differences
wilcox.test(propQuit ~ cond, data = subset(qtData, distribution == 1), paired = F) # Test differences

# Experienced reward rate between treatments
with(subset(qtData,distribution == 2), tapply(rewardRate, cond, mean)) # Get means
with(subset(qtData,distribution == 2), tapply(rewardRate, cond, sd)) # Get SDs
with(qtData, tapply(rewardRate, distribution, shapiro.test)) # Significance implies non-normality
wilcox.test(rewardRate ~ cond, data = subset(qtData, distribution == 1), paired = F) # Test differences
t.test(rewardRate ~ cond, data = subset(qtData, distribution == 2), paired = F)

ezANOVA(data = qtData, dv = rewardRate, wid = id, 
        within = .(distribution), between = .(cond),
        type = 3, detailed = T, return_aov = F)
ezPlot(x = distribution, data = qtData, 
       dv = rewardRate, wid = id, split = cond,
       within = .(distribution), between = .(cond), 
       type = 3)

summary(lm(rewardRate ~ distribution + cond, data = qtData))
require("quantreg")
qs = 1:9/10
fit1 <- rq(rewardRate ~ distribution + cond, data = qtData, tau = qs)
summary(fit1, se = "nid")
plot(fit1)
fit2 <- rq(k3 ~ meanHR + as.factor(condition), data = data, tau = qs)
summary(fit2, se = "nid")
plot(fit2)

# All blocks (rewrd rate)
rewardRate <- aggregate(rr ~ id + distribution + block + drink, data = trialData[, c("id","distribution","block","drink","rr")],
                        FUN = function(x) c(M = mean(x)))

# Add condition variable
rewardRate[rewardRate$id < 26,"cond"] <- 1 # Gluc
rewardRate[rewardRate$id >= 26,"cond"] <- 2 # Water
# Refactor
rewardRate$drink <- factor(rewardRate$drink)
rewardRate$cond <- factor(rewardRate$cond)
rewardRate$distribution <- factor(rewardRate$distribution)

ezANOVA(data = subset(rewardRate,block >2), dv = rr, wid = id, 
        within = .(distribution, drink), between = .(cond),
        type = 3, detailed = T, return_aov = F)
ezDesign(subset(rewardRate,block >2),
         x = id, 
         y = block, 
         cell_border_size = 1)
ezPlot(x = drink, data = subset(rewardRate,block > 2 & distribution == 2), 
       dv = rr, wid = id, split = cond,
       within = .(drink), between = .(cond), 
       type = 3)

# Earnings between treatments
with(subset(qtData,distribution == 2), tapply(earnings, cond, median)) # Get means
with(subset(qtData,distribution == 2), tapply(earnings, cond, sd)) # Get SDs
with(qtData, tapply(earnings, distribution, shapiro.test)) # Significance implies non-normality
wilcox.test(earnings ~ cond, data = subset(qtData, distribution == 2), paired = F) # Test differences
t.test(earnings ~ cond, data = subset(qtData, distribution == 2), paired = F)

# Correlations
require(Hmisc)
require(xtable)
source("/Users/Bowen/Documents/R/misc functions/corrstars.R")
corrstars(as.matrix(qtData[,4:11]), type = "spearman", method = "none")
rcorr(as.matrix(qtData[, 4:11]), type = "spearman") # Exact p-values
xtable(corrstars(as.matrix(qtData[,4:11]), type = "spearman", method = "none")) # Print in LaTeX

temp <- subset(qtData, !(id %in% c(6,16,18,30,32,34)))
corrstars(temp[,c("M","AUC")])
wilcox.test(AUC ~ distribution, data = temp, paired = T) # Test differences
t.test(AUC ~ cond, data = subset(temp,distribution == 1), paired = F) # Test differences

