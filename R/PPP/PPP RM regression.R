# PPP repeated measures analysis
## Bowen J Fung, 2016

### Load data
trialData <- read.csv("~/Documents/R/PPP/trialDataAll.txt") # Contains all experiments
#trialData <- read.csv("~/Documents/R/PPP/trialDataGlucose(clean).txt")

require(ez)
require(lsr)
require(ggplot2)

### Subset to type (1 = juice, 2 = money, 3 = water, 4 = aspartame, 5 = glucose)
trialData <- trialData[trialData$type == 5,]

## Carry-over effects
### Temporal
require(data.table)
dt <- data.table(trialData)
t.test(dt[,lm(response ~ delay + lagDelay)$coefficients[3], by = id]$V1)
cohensD(dt[,lm(response ~ delay + lagDelay)$coefficients[3], by = id]$V1)
### Decisional
t.test(dt[,lm(response ~ delay + lagResponse)$coefficients[3], by = id]$V1)
cohensD(dt[,lm(response ~ delay + lagResponse)$coefficients[3], by = id]$V1)

### Subset data to useful variables
desiredVars = c("session","id","response","delay","reward","accuracy","normAccuracy","lagReward","lagDelay")
trialData <- trialData[desiredVars]

## Delay effects
      pip <- aggregate(response ~ id + delay, data = trialData, 
                       FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      names(pip) <- c("id","delay","response")
      pip <- cbind(pip[,c("id","delay")], data.frame(pip$response))
      pip <- within(pip, {
        id <- factor(id)
        delay <- factor(delay)
      })
      
      # Means
      ezANOVA(data = pip, dv = M, wid = id, within = .(delay), type = 3)
      ezPlot(x = delay, data = pip, dv = M, wid = id, within = .(delay), type = 3)
      pairwise.t.test(pip$M, pip$delay, p.adjust.method = "holm", paired = T)
      t.test(pip[pip$delay == 8,"M"],pip[pip$delay == 10,"M"], paired = T)
      
      # SDs
      ezANOVA(data = pip, dv = SD, wid = id, within = .(delay), type = 3)
      ezPlot(x = delay, data = pip, dv = SD, wid = id, within = .(delay), type = 3)
      pairwise.t.test(pip$SD, pip$delay, p.adjust.method = "holm", paired = T)$p.value
      t.test(pip[pip$delay == 8,"SD"],pip[pip$delay == 10,"SD"], paired = T)
      
      # CVs
      ezANOVA(data = pip, dv = CV, wid = id, within = .(delay), type = 3)
      ezPlot(x = delay, data = pip, dv = CV, wid = id, within = .(delay), type = 3)
      pairwise.t.test(pip$CV, pip$delay, p.adjust.method = "holm", paired = F)
      t.test(pip[pip$delay == 8,"CV"],pip[pip$delay == 10,"CV"], paired = T)
      
## Baslinelines vs Main task (have elected to ignore delay and just use normAccuracy as dv)
      pip <- aggregate(normAccuracy ~ id + session, data = trialData, 
                        FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      names(pip) <- c("id","session","response")
      pip <- cbind(pip[,c("id","session")], data.frame(pip$response))
      pip <- within(pip, {
        id <- factor(id)
        session <- factor(session)
      })
      ezANOVA(data = pip, dv = M, wid = id, within = .(session), type = 3)
      ezPlot(x = session, data = pip, dv = M, wid = id, within = .(session), type = 3)
      
      # Pairwise t-tests 
#       (need to collapse delay if used above)
#       pipT <- aggregate(M ~ id + session, data = pip, 
#                         FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
#       names(pipT) <- c("id","session","response")
#       pipT <- cbind(pipT[,c("id","session")], data.frame(pipT$response))
#       
      pairwise.t.test(pip$M, pip$session, p.adjust.method = "holm", paired = T)$p.value
      
      # Pooled baselines unpaired t-test  
      # t.test(pip[pip$session == 2,"M"], pip[pip$session %in% c(1,3),"M"], paired = F)
      # cohensD(pip[pip$session == 2,"M"], pip[pip$session %in% c(1,3),"M"], method = "unequal")
      
      # Averaged baselines t-test
      t.test(pip[pip$session == 1,"M"], pip[pip$session == 3,"M"], paired = T) # Check for differences b/w 1 and 3
      cohensD(pip[pip$session == 1,"M"], pip[pip$session == 3,"M"], method = "paired")
      
      baseline <- rowMeans(cbind(pip[pip$session == 1,"M"],pip[pip$session == 3,"M"])) # Average 1 and 3
      t.test(baseline,pip[pip$session == 2,"M"], paired = T) # Test 1 and 4
      cohensD(baseline,pip[pip$session == 2,"M"], method = "paired")
      
      t.test(pip[pip$session == 2,"M"], pip[pip$session == 1,"M"], paired = T) # Test 1 and 2
      cohensD(pip[pip$session == 2,"M"], pip[pip$session == 1,"M"], method = "paired")
      
      t.test(pip[pip$session == 2,"M"], pip[pip$session == 3,"M"], paired = T) # Test 2 and 3
      cohensD(pip[pip$session == 2,"M"], pip[pip$session == 3,"M"], method = "paired")
      
      
      # Do a little plot
      pipSessions <- aggregate(M ~ session, data = pip, 
                               FUN = function(x) c(M = mean(x), SEM = sd(x) / sqrt(length(x))))
      ggplot(pipSessions, aes(x = session, y = M[,"M"])) +  
        geom_errorbar(aes(ymin = M[,"M"]-M[,"SEM"], 
                          ymax = M[,"M"]+M[,"SEM"]))

# Drop baselines
trialData <- subset(trialData, session == 2)

## Anticipated reward (mean)
      pip <- aggregate(response ~ id + delay + reward, data = trialData, 
                       FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      names(pip) <- c("id","delay","reward","response")
      pip <- cbind(pip[,c("id","delay","reward")], data.frame(pip$response))
      pip <- within(pip, {
        id <- factor(id)
        delay <- factor(delay)
        reward <- factor(reward, levels = c("none", "small", "medium", "large"), ordered = T)
      })
      
      ezANOVA(data = pip, dv = M, wid = id, within = .(delay,reward), type = 3)
      ezStats(data = pip, dv = M, wid = id, within = .(delay,reward), type = 3)
      ezPlot(x = reward, data = pip, dv = M, wid = id, within = .(reward), type = 3)
      
      # Collapse reward levels and test 0 versus 1
      pipCollapsed <- pip
      levels(pipCollapsed$reward) <- list(reward = c("none"), noReward = c("small","medium","large"))
      ezANOVA(data = pipCollapsed, dv = M, wid = id, within = .(delay,reward), type = 3)
      ezStats(data = pipCollapsed, dv = M, wid = id, within = .(delay,reward), type = 3)
      ezPlot(x = reward, data = pipCollapsed, dv = M, wid = id, within = .(reward), type = 3)
      
      # Pairwise t-tests (collapsing delay)
      pipT <- aggregate(M ~ id + reward, data = pip, 
                        FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      names(pipT) <- c("id","reward","response")
      pipT <- cbind(pipT[,c("id","reward")], data.frame(pipT$response))
      
      pairwise.t.test(pipT$M, pipT$reward, p.adjust.method = "none", paired = T)$p.value
      
      # Simple effects (for interaction)
      ezPlot(x = reward, data = pip, dv = M, wid = id, within = .(reward,delay), split = delay, type = 3)
      
      d1 <- ezANOVA(data = pip[pip$delay == 4,], dv = M, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 4,"M"], pip[pip$delay == 4,"reward"], 
                      paired = T, p.adjust.method = "none")
      
      t.test(pip[pip$delay == 4 & pip$reward == 1.2,"M"],pip[pip$delay == 4 & pip$reward == 2.3,"M"], paired = T)
      
      d2 <- ezANOVA(data = pip[pip$delay == 6,], dv = M, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 6,"M"], pip[pip$delay == 6,"reward"], 
                      paired = T, p.adjust.method = "none")
      
      d3 <- ezANOVA(data = pip[pip$delay == 8,], dv = M, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 8,"M"], pip[pip$delay == 8,"reward"], 
                      paired = T, p.adjust.method = "none")
      
      d4 <- ezANOVA(data = pip[pip$delay == 10,], dv = M, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 10,"M"], pip[pip$delay == 10,"reward"], 
                      paired = T, p.adjust.method = "none")
      
      pVals <- c(d1$ANOVA$p, d2$ANOVA$p, d3$ANOVA$p, d4$ANOVA$p) # Make sure these do not violate sphericity
      holmCorr <- p.adjust(pVals, method = "holm");
      
## Anticipated reward (sd)
      ezANOVA(data = pip, dv = SD, wid = id, within = .(delay,reward), type = 3)
      ezStats(data = pip, dv = SD, wid = id, within = .(delay,reward), type = 3)
      ezPlot(x = reward, data = pip, dv = SD, wid = id, within = .(reward), type = 3)
      
      # Pairwise t-tests (collapsing delay)
      pipT <- aggregate(SD ~ id + reward, data = pip, 
                        FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      names(pipT) <- c("id","reward","response")
      pipT <- cbind(pipT[,c("id","reward")], data.frame(pipT$response))
      
      pairwise.t.test(pipT$SD, pipT$reward, p.adjust.method = "none", paired = T)$p.value
      
      # Simple effects (for interaction)
      ezPlot(x = reward, data = pip, dv = SD, wid = id, within = .(reward,delay), split = delay, type = 3)
      
      ezANOVA(data = pip[pip$delay == 4,], dv = SD, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 4,"M"], pip[pip$delay == 4,"reward"], 
                      paired = T, p.adjust.method = "none")
      
      ezANOVA(data = pip[pip$delay == 6,], dv = SD, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 6,"M"], pip[pip$delay == 6,"reward"], 
                      paired = T, p.adjust.method = "none")
      
      ezANOVA(data = pip[pip$delay == 8,], dv = SD, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 8,"M"], pip[pip$delay == 8,"reward"], 
                      paired = T, p.adjust.method = "none")
      
      ezANOVA(data = pip[pip$delay == 10,], dv = SD, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 10,"M"], pip[pip$delay == 10,"reward"], 
                      paired = T, p.adjust.method = "none")

## Anticipated reward (cv)
      ezANOVA(data = pip, dv = CV, wid = id, within = .(delay,reward), type = 3)
      ezStats(data = pip, dv = CV, wid = id, within = .(delay,reward), type = 3)
      ezPlot(x = reward, data = pip, dv = CV, wid = id, within = .(reward), type = 3)
      
      # Pairwise t-tests (collapsing delay)
      pipT <- aggregate(CV ~ id + reward, data = pip, 
                        FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      names(pipT) <- c("id","reward","response")
      pipT <- cbind(pipT[,c("id","reward")], data.frame(pipT$response))
      
      pairwise.t.test(pipT$M, pipT$reward, p.adjust.method = "none", paired = T)$p.value
      
      # Simple effects (for interaction)
      ezPlot(x = reward, data = pip, dv = CV, wid = id, within = .(reward,delay), split = delay, type = 3)
      
      ezANOVA(data = pip[pip$delay == 4,], dv = CV, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 4,"M"], pip[pip$delay == 4,"reward"], 
                      paired = T, p.adjust.method = "none")
      
      ezANOVA(data = pip[pip$delay == 6,], dv = CV, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 6,"M"], pip[pip$delay == 6,"reward"], 
                      paired = T, p.adjust.method = "none")
      
      ezANOVA(data = pip[pip$delay == 8,], dv = CV, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 8,"M"], pip[pip$delay == 8,"reward"], 
                      paired = T, p.adjust.method = "none")
      
      ezANOVA(data = pip[pip$delay == 10,], dv = CV, wid = id, within = .(reward), type = 3)
      pairwise.t.test(pip[pip$delay == 10,"M"], pip[pip$delay == 10,"reward"], 
                      paired = T, p.adjust.method = "none")
      
## Previous reward (mean)
pip <- aggregate(response ~ id + delay + lagReward, data = trialData, 
                 FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
names(pip) <- c("id","delay","lagReward","response")
pip <- cbind(pip[,c("id","delay","lagReward")], data.frame(pip$response))
pip <- within(pip, {
  id <- factor(id)
  delay <- factor(delay)
  lagReward <- factor(lagReward, levels = c("none", "small", "medium", "large"), ordered = T)
})
      
      ezANOVA(data = pip, dv = M, wid = id, within = .(delay,lagReward), type = 3)
      ezStats(data = pip, dv = M, wid = id, within = .(delay,lagReward), type = 3)
      ezPlot(x = lagReward, data = pip, dv = M, wid = id, within = .(lagReward), type = 3,
             x_lab = "Previous reward magnitude", y_lab = "Mean time estimate")
      ezDesign(data = pip, x = id, y = lagReward, col = delay)
      
      # Collapse reward levels and test 0 versus 1
      pipCollapsed <- pip
      levels(pipCollapsed$lagReward) <- list(reward = c("none"), noReward = c("small","medium","large"))
      ezANOVA(data = pipCollapsed, dv = M, wid = id, within = .(delay,lagReward), type = 3)
      ezStats(data = pipCollapsed, dv = M, wid = id, within = .(delay,lagReward), type = 3)
      ezPlot(x = lagReward, data = pipCollapsed, dv = M, wid = id, within = .(lagReward), type = 3)

      # Pairwise t-tests (collapsing delay)
      pipT <- aggregate(M ~ id + lagReward, data = pip, 
                        FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      names(pipT) <- c("id","lagReward","response")
      pipT <- cbind(pipT[,c("id","lagReward")], data.frame(pipT$response))
      
      pairwise.t.test(pipT$M, pipT$lagReward, p.adjust.method = "none", paired = T)$p.value
      
      t.test(pipT[pipT$lagReward == 1.2,"M"],pipT[pipT$lagReward == 2.3,"M"], paired = T)
      
      # Simple effects (for interaction)
      ezPlot(x = lagReward, data = pip, dv = M, wid = id, within = .(lagReward,delay), split = delay, type = 3)
      
      ezANOVA(data = pip[pip$delay == 4,], dv = M, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 4,"M"], pip[pip$delay == 4,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      ezANOVA(data = pip[pip$delay == 6,], dv = M, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 6,"M"], pip[pip$delay == 6,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      ezANOVA(data = pip[pip$delay == 8,], dv = M, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 8,"M"], pip[pip$delay == 8,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      ezANOVA(data = pip[pip$delay == 10,], dv = M, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 10,"M"], pip[pip$delay == 10,"lagReward"], 
                      paired = T, p.adjust.method = "none")

## Previous reward (sd)
      ezANOVA(data = pip, dv = SD, wid = id, within = .(delay,lagReward), type = 3)
      ezStats(data = pip, dv = SD, wid = id, within = .(delay,lagReward), type = 3)
      ezPlot(x = lagReward, data = pip, dv = SD, wid = id, within = .(lagReward), type = 3)
      
      
      # Pairwise t-tests (collapsing delay)
      pipT <- aggregate(SD ~ id + lagReward, data = pip, 
                        FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      names(pipT) <- c("id","lagReward","response")
      pipT <- cbind(pipT[,c("id","lagReward")], data.frame(pipT$response))
      
      pairwise.t.test(pipT$SD, pipT$lagReward, p.adjust.method = "none", paired = T)$p.value
      
      # Simple effects (for interaction)
      ezPlot(x = lagReward, data = pip, dv = SD, wid = id, within = .(lagReward,delay), split = delay, type = 3)
      
      d1 <- ezANOVA(data = pip[pip$delay == 4,], dv = SD, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 4,"M"], pip[pip$delay == 4,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      d2 <- ezANOVA(data = pip[pip$delay == 6,], dv = SD, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 6,"M"], pip[pip$delay == 6,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      d3 <- ezANOVA(data = pip[pip$delay == 8,], dv = SD, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 8,"M"], pip[pip$delay == 8,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      d4 <- ezANOVA(data = pip[pip$delay == 10,], dv = SD, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 10,"M"], pip[pip$delay == 10,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      pVals <- c(d1$ANOVA$p, d2$ANOVA$p, d3$ANOVA$p, d4$ANOVA$p) # Make sure these do not violate sphericity
      holmCorr <- p.adjust(pVals, method = "holm");
      
## Previous reward (cv)
      ezANOVA(data = pip, dv = CV, wid = id, within = .(delay,lagReward), type = 3)
      ezStats(data = pip, dv = CV, wid = id, within = .(delay,lagReward), type = 3)
      
      # Pairwise t-tests (collapsing delay)
      pipT <- aggregate(CV ~ id + lagReward, data = pip, 
                        FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      names(pipT) <- c("id","lagReward","response")
      pipT <- cbind(pipT[,c("id","lagReward")], data.frame(pipT$response))
      
      pairwise.t.test(pipT$CV, pipT$lagReward, p.adjust.method = "none", paired = T)$p.value
      
      # Simple effects (for interaction)
      ezPlot(x = lagReward, data = pip, dv = CV, wid = id, within = .(lagReward,delay), split = delay, type = 3)
      
      d1 <- ezANOVA(data = pip[pip$delay == 4,], dv = CV, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 4,"M"], pip[pip$delay == 4,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      d2 <- ezANOVA(data = pip[pip$delay == 6,], dv = CV, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 6,"M"], pip[pip$delay == 6,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      d3 <- ezANOVA(data = pip[pip$delay == 8,], dv = CV, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 8,"M"], pip[pip$delay == 8,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      d4 <- ezANOVA(data = pip[pip$delay == 10,], dv = CV, wid = id, within = .(lagReward), type = 3)
      pairwise.t.test(pip[pip$delay == 10,"M"], pip[pip$delay == 10,"lagReward"], 
                      paired = T, p.adjust.method = "none")
      
      pVals <- c(d1$ANOVA$p, d2$ANOVA$p, d3$ANOVA$p, d4$ANOVA$p) # Make sure these do not violate sphericity
      holmCorr <- p.adjust(pVals, method = "holm");
      
# Sequence effects (can't do repeated measures ANOVA as we are there are not enough trials for every participant)
      require(zoo)
      # Find indices for first pattern
      patrn = c(0,2.8)
      exmpl <- trialData$reward
      matches1 <- which(rollapply(exmpl, 2, identical, patrn, fill = FALSE, align = "left")) + 2 # Returns first index of first in sequence, so we add 2 to find the trial of interest
      
      # Aggregate these responses
      larger <- aggregate(normAccuracy ~ id, data = trialData[matches1,], 
                       FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      larger <- cbind(larger, 1)
      names(larger) <- c("id","response","larger")

      # Find indices for second pattern
      patrn = c(2.8,0)
      exmpl <- trialData$reward
      matches2 <- which(rollapply(exmpl, 2, identical, patrn, fill = FALSE, align = "left")) + 2 # Returns first index of first in sequence, so we add 2 to find the trial of interest
      
      # Aggregate these responses
      smaller <- aggregate(normAccuracy ~ id , data = trialData[matches2,], 
                           FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      smaller <- cbind(smaller, 0)
      names(smaller) <- c("id","response","larger")
      
      # Join data frames, rename and change to factors
      pip <- rbind(larger,smaller)
      pip <- cbind(pip[,c("id","larger")], data.frame(pip$response))
      pip <- within(pip, {
        id <- factor(id)
        larger <- factor(larger)
      })
      
      # Run analysis
      t.test(pip[pip$larger == 1,"M"],pip[pip$larger == 0,"M"], paired = T)
      ezPlot(x = larger, data = pip, dv = M, wid = id, within = .(larger))
      
# Generate means table
      pip <- aggregate(response ~ id + reward + delay, data = trialData, 
                       FUN = function(x) c(M = mean(x)))
      pipM <- aggregate(response ~ reward + delay, data = pip, 
                       FUN = function(x) c(M = mean(x), SD = sd(x), N = length(x)))
      
      
# Combined plots for previous rewards
trialData <- read.csv("~/Documents/R/PPP/trialDataPPP.txt")
trialData <- subset(trialData, flag == 0) # Subset to clean data (this will remove participants 10,23,28,34,49)
trialData <- subset(trialData, session == 2)

lagmatrix <- function(x,max.lag) embed(c(rep(NA,max.lag), x), max.lag+1)

for (i in unique(trialData$id)) {
  lagRew <- lagmatrix(trialData[trialData$id == i, "reward"], 5)
  trialData[trialData$id == i, "lagReward"] <- lagRew[,5] # Choose lag here (1 is normal)
}

pip <- aggregate(response ~ id + type + delay + lagReward, data = trialData, 
                       FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
names(pip) <- c("id","type","delay","lagReward","response")
pip <- cbind(pip[,c("id","type","delay","lagReward")], data.frame(pip$response))
pip <- within(pip, {
id <- factor(id)
type <- factor(type)
delay <- factor(delay)
lagReward <- factor(lagReward)
      })
      
mdl <- ezANOVA(data = pip, dv = M, wid = id, within = .(delay,lagReward), between = .(type), type = 3)
ezStats(data = pip, dv = M, wid = id, within = .(delay,lagReward), type = 3)
ezPlot(x = lagReward, data = pip, dv = M, wid = id, split = type, within = .(lagReward), between = .(type), type = 3,
             x_lab = "Previous reward magnitude", y_lab = "Mean time estimate", split_lab = "Treatment condition",
             levels = list(lagReward = list(new_names = c("None","Small","Medium","Large")), type = list(new_names = c("Maltodextrin","Aspartame"))))
ezDesign(data = pip, x = id, y = lagReward, col = delay)


require(xtable)
xtable(mdl$ANOVA)

# Plots for all experiments
trialData <- read.csv("~/Documents/R/PPP/trialDataAll.txt") # Contains all experiments, reward codes matched

# Baselines
pip <- aggregate(normAccuracy ~ id + type + session, data = trialData, 
                 FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
names(pip) <- c("id","type","session","response")
pip <- cbind(pip[,c("id","type","session")], data.frame(pip$response))
pip <- within(pip, {
  id <- factor(id)
  type <- factor(type)
  session <- factor(session)
})

stats <- ezPlot(x = session, data = pip, dv = M, wid = id, within = .(session), between = (type), split = type, type = 3,
               x_lab = "Task phase", y_lab = "Time estimate difference (SD)", split_lab = "Experiment", print_code = T)

# Boxplot
ggplot(data = pip, aes(x = session, y = M, fill = type)) +
  geom_boxplot(outlier.size = 0.5, alpha = 0.7) + 
  scale_fill_brewer(palette = "Spectral", labels = c("1 (Juice)", "2 (Money)", "3 (Water)", "4 (Aspartame)", "5 (Maltodextrin)")) + 
  labs(x = 'Task phase', y = 'Time estimate difference (SD)', fill = 'Experiment') +
  theme(text = element_text(size = 18))

# Line plot (Fig 2)
ggplot(data = stats, aes(x = session, y = Mean, color = type, ymin = lo, ymax = hi)) +
  geom_point(alpha = 0.9, size = 2) + geom_line(aes(group = type), alpha = 0.9, size = 0.8) + geom_errorbar(alpha = 0.4, width = 0.2) +
  labs(x = 'Task phase', y = 'Time estimate difference (SD)', colour = 'Experiment') + 
  scale_colour_brewer(palette = "Spectral", labels = c("1 (Juice)", "2 (Money)", "3 (Water)", "4 (Aspartame)", "5 (Maltodextrin)")) + 
  theme(text = element_text(size = 18))

# Bootstrapped CIs
bt <- ezBoot(data = trialData, dv = normAccuracy, wid = id, within = .(session), between = (type),
             resample_within = T,
             iterations = 1e3,
             lmer = FALSE,
             lmer_family = gaussian)

ezPlot2(preds = bt, x = session, split = type,
        x_lab = "Task phase", y_lab = "Time estimate difference (SD)", split_lab = "Experiment") 

## Anticipated reward (mean)
pip <- aggregate(response ~ id + type + delay + reward, data = subset(trialData, session == 2), 
                 FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
names(pip) <- c("id","type","delay","reward","response")
pip <- cbind(pip[,c("id","type","delay","reward")], data.frame(pip$response))
pip <- within(pip, {
  id <- factor(id)
  type <- factor(type)
  delay <- factor(delay)
  reward <- factor(reward, levels = c("none", "small", "medium", "large"), ordered = T)
})

ezANOVA(data = pip, dv = M, wid = id, within = .(delay,reward), between = .(type), type = 3)
ezStats(data = pip, dv = M, wid = id, within = .(delay,reward), between = .(type), type = 3)
ezPlot(x = reward, data = pip, dv = M, wid = id, within = .(reward), between = .(type), split = type, type = 3,
       x_lab = "Anticipated reward magnitude", y_lab = "Mean time estimate")
ezDesign(data = pip, x = id, y = reward, col = delay)

# Collapse reward levels and test 0 versus 1
pipCollapsed <- pip
levels(pipCollapsed$reward) <- list("No reward" = c("none"), "Reward" = c("small","medium","large"))
ezANOVA(data = pipCollapsed, dv = M, wid = id, within = .(delay,reward), type = 3)
ezStats(data = pipCollapsed, dv = M, wid = id, within = .(delay,reward), type = 3)

stats <- ezPlot(x = reward, data = pipCollapsed, dv = M, wid = id,
       within = .(reward), between = .(type), split = type, type = 3,
       x_lab = "Anticipated reward", y_lab = "Mean time estimate", split_lab = "Experiment", print_code = T)

# Line plot (Fig 3)
ggplot(data = stats, aes(x = reward, y = Mean, color = type, ymin = lo, ymax = hi)) +
  geom_point(alpha = 0.9, size = 2) + geom_line(aes(group = type), alpha = 0.9, size = 0.8) + geom_errorbar(alpha = 0.4, width = 0.2) +
  labs(x = 'Anticipated Reward', y = 'Mean time estimate', colour = 'Experiment') + 
  scale_colour_brewer(palette = "Spectral", labels = c("1 (Juice)", "2 (Money)", "3 (Water)", "4 (Aspartame)", "5 (Maltodextrin)")) + 
  theme(text = element_text(size = 18))

# Bootstrapped CIs
bt <- ezBoot(data = subset(trialData, session == 2), dv = response, wid = id, within = .(delay,reward), between = (type),
             resample_within = T,
             iterations = 1e3,
             lmer = FALSE,
             lmer_family = gaussian)

ezPlot2(preds = bt, x = reward, split = type,
        x_lab = "Anticipated reward", y_lab = "Time estimate difference (SD)", split_lab = "Experiment", 
        levels = list(reward = list(
            new_order = c("none", "small", "medium", "large"))))

## Previous reward (mean)
pip <- aggregate(response ~ id + type + delay + lagReward, data = subset(trialData, session == 2), 
                 FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
names(pip) <- c("id","type","delay","lagReward","response")
pip <- cbind(pip[,c("id","type","delay","lagReward")], data.frame(pip$response))
pip <- within(pip, {
  id <- factor(id)
  type <- factor(type)
  delay <- factor(delay)
  lagReward <- factor(lagReward, levels = c("none", "small", "medium", "large"), ordered = T)
})

ezANOVA(data = pip, dv = M, wid = id, within = .(delay,lagReward), between = .(type), type = 3)
s <- ezStats(data = pip, dv = M, wid = id, within = .(delay,lagReward), between = .(type), type = 3)
stats <- ezPlot(x = lagReward, data = pip, dv = M, wid = id, within = .(lagReward), between = .(type), split = type, type = 3,
       x_lab = "Previous reward magnitude", y_lab = "Mean time estimate", split_lab = "Experiment", print_code = T)
ezDesign(data = pip, x = id, y = lagReward, col = delay)

# Line plot (Fig S2)
ggplot(data = stats, aes(x = lagReward, y = Mean, color = type, ymin = lo, ymax = hi)) +
  geom_point(alpha = 0.9, size = 2) + geom_line(aes(group = type), alpha = 0.9, size = 0.8) + geom_errorbar(alpha = 0.6, width = 0.2) +
  labs(x = 'Previous Reward', y = 'Mean time estimate', colour = 'Experiment') + 
  scale_colour_brewer(palette = "Spectral", labels = c("1 (Juice)", "2 (Money)", "3 (Water)", "4 (Aspartame)", "5 (Maltodextrin)")) + 
  theme(text = element_text(size = 18))

# Collapse reward levels and test 0 versus 1
pipCollapsed <- pip
levels(pipCollapsed$lagReward) <- list("No reward" = c("none"), "Reward" = c("small","medium","large"))
ezANOVA(data = pipCollapsed, dv = M, wid = id, within = .(delay,lagReward), type = 3)
ezStats(data = pipCollapsed, dv = M, wid = id, within = .(delay,lagReward), type = 3)
stats <- ezPlot(x = lagReward, data = pipCollapsed, dv = M, wid = id,
       within = .(lagReward), between = .(type), split = type, type = 3,
       x_lab = "Previously consumed reward", y_lab = "Mean time estimate", split_lab = "Experiment", print_code = T)

# Line plot (Fig 4)
ggplot(data = stats, aes(x = lagReward, y = Mean, color = type, ymin = lo, ymax = hi)) +
  geom_point(alpha = 0.9, size = 2) + geom_line(aes(group = type), alpha = 0.9, size = 0.8) + geom_errorbar(alpha = 0.4, width = 0.2) +
  labs(x = 'Previous Reward', y = 'Mean time estimate', colour = 'Experiment') + 
  scale_colour_brewer(palette = "Spectral", labels = c("1 (Juice)", "2 (Money)", "3 (Water)", "4 (Aspartame)", "5 (Maltodextrin)")) + 
  theme(text = element_text(size = 18))

# Bootstrapped CIs
bt <- ezBoot(data = pipCollapsed, dv = M, wid = id, within = .(delay,lagReward), between = (type),
             resample_within = T,
             iterations = 1e3,
             lmer = FALSE,
             lmer_family = gaussian)

ezPlot2(preds = bt, x = lagReward, split = type,
        x_lab = "Previous reward", y_lab = "Time estimate difference (SD)", split_lab = "Experiment",
        levels = list(lagReward = list(new_order = c("none", "small", "medium", "large"))))

# 
pip <- aggregate(response ~ id + delay + reward + lagReward, data = trialData, 
                 FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
names(pip) <- c("id","delay","reward", "lagReward","response")
pip <- cbind(pip[,c("id","delay","reward","lagReward")], data.frame(pip$response))
pip <- within(pip, {
  id <- factor(id)
  delay <- factor(delay)
  reward <- factor(reward, levels = c("none", "small", "medium", "large"), ordered = T)
  lagReward <- factor(lagReward, levels = c("none", "small", "medium", "large"), ordered = T)
})

ezDesign(data = pip, x = M, y = delay, row = reward, col = lagReward)

ezANOVA(data = pip, dv = M, wid = id, within = .(delay,reward,lagReward), type = 3)
ezStats(data = pip, dv = M, wid = id, within = .(delay,reward), type = 3)
ezPlot(x = reward, data = pip, dv = M, wid = id, within = .(reward), type = 3)

# Collapse reward levels and test 0 versus 1
pipCollapsed <- pip
levels(pipCollapsed$reward) <- list(reward = c("none"), noReward = c("small","medium","large"))
ezANOVA(data = pipCollapsed, dv = M, wid = id, within = .(delay,reward), type = 3)
ezStats(data = pipCollapsed, dv = M, wid = id, within = .(delay,reward), type = 3)
ezPlot(x = reward, data = pipCollapsed, dv = M, wid = id, within = .(reward), type = 3)


### Both anticipated and previously consumed reward (mean)
# This only works for collapsed data, and only for experiment 1, otherwise cells are missing
pip <- aggregate(response ~ id + delay + reward + lagReward, data = trialData, 
                 FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
names(pip) <- c("id","delay","reward","lagReward","response")
pip <- cbind(pip[,c("id","delay","reward","lagReward")], data.frame(pip$response))
pip <- within(pip, {
  id <- factor(id)
  delay <- factor(delay)
  reward <- factor(reward, levels = c("none", "small", "medium", "large"), ordered = T)
  lagReward <- factor(lagReward, levels = c("none", "small", "medium", "large"), ordered = T)
})
pipCollapsed <- pip
levels(pipCollapsed$reward) <- list(reward = c("none"), noReward = c("small","medium","large"))
levels(pipCollapsed$lagReward) <- list(lagReward = c("none"), noReward = c("small","medium","large"))

ezANOVA(data = pipCollapsed, dv = M, wid = id, within = .(delay,reward,lagReward), type = 3)
ezDesign(data = pipCollapsed, x = lagReward, y = reward, row = delay, col = id)