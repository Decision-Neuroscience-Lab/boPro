# PIP repeated measures analysis
## Bowen J Fung, 2015

### Load data
trialData <- read.csv("~/Documents/R/PIP/trialDataAll(clean).txt")
require(ez)
require(ggplot2)

### Subset to type (1 = juice, 2 = money, 3 = water, 4 = pilot)
trialData <- trialData[trialData$type == 1,]

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
      pairwise.t.test(pip$CV, pip$delay, p.adjust.method = "none", paired = F)
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
      pairwise.t.test(pip$M, pip$session, p.adjust.method = "none", paired = T)$p.value
      
      # Pooled baselines unpaired t-test  
      t.test(pip[pip$session == 2,"M"], pip[pip$session %in% c(1,3),"M"], paired = F)
      # Averaged baselines t-test
      t.test(pip[pip$session == 1,"M"], pip[pip$session == 3,"M"], paired = T) # Check for differences b/w 1 and 3
      baseline <- rowMeans(cbind(pip[pip$session == 1,"M"],pip[pip$session == 3,"M"])) # Average 1 and 3
      t.test(baseline,pip[pip$session == 2,"M"], paired = T)
      
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
        reward <- factor(reward)
      })
      
      ezANOVA(data = pip, dv = M, wid = id, within = .(delay,reward), type = 3)
      ezStats(data = pip, dv = M, wid = id, within = .(delay,reward), type = 3)
      ezPlot(x = reward, data = pip, dv = M, wid = id, within = .(reward), type = 3)
      
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
                      paired = T, p.adjust.method = "holm")
      
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
      
      # Pairwise t-tests (collapsing delay)
      pipT <- aggregate(CV ~ id + reward, data = pip, 
                        FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      names(pipT) <- c("id","reward","response")
      pipT <- cbind(pipT[,c("id","reward")], data.frame(pipT$response))
      
      pairwise.t.test(pipT$CV, pipT$reward, p.adjust.method = "none", paired = T)$p.value
      
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
  lagReward <- factor(lagReward)
})
      
      ezANOVA(data = pip, dv = M, wid = id, within = .(delay,lagReward), type = 3)
      ezStats(data = pip, dv = M, wid = id, within = .(delay,lagReward), type = 3)
      ezPlot(x = lagReward, data = pip, dv = M, wid = id, within = .(lagReward), type = 3)
      
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
      patrn = c(0,2.3)
      exmpl <- trialData$reward
      matches1 <- which(rollapply(exmpl, 2, identical, patrn, fill = FALSE, align = "left")) + 2 # Returns first index of first in sequence, so we add 2 to find the trial of interest
      
      # Aggregate these responses
      larger <- aggregate(normAccuracy ~ id, data = trialData[matches1,], 
                       FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
      larger <- cbind(larger, 1)
      names(larger) <- c("id","response","larger")

      # Find indices for second pattern
      patrn = c(2.3,0)
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
      