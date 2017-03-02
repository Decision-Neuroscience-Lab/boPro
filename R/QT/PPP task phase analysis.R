# PPP task phase analysis
## Bowen J Fung, 2016

# Load and clean data
trialData <- read.csv("~/Documents/R/PPP/trialDataPPP.txt")
physiologicalData <- read.csv("~/Documents/R/PPP/physiological.txt")

trialData <- subset(trialData, flag == 0) # Subset to clean data (this will remove participant 10,23,28,34,49 due to attention criteria) 
physiologicalData <- subset(physiologicalData, id %in% unique(trialData$id)) # Also remove from physData

# Aggregate behavioural data
desiredVars = c("session","type","id","response","delay","reward","accuracy","normAccuracy","lagReward","lagDelay")
trialData <- trialData[desiredVars]

pppSessions <- aggregate(normAccuracy ~ id + type + session, data = trialData, 
                         FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x)/sd(x), N = length(x)))
names(pppSessions) <- c("id","type","session","response")
pppSessions <- cbind(pppSessions[,c("id","type","session")], data.frame(pppSessions$response))

pppSessions <- pppSessions[order(pppSessions$id), ]
physiologicalData <- physiologicalData[order(physiologicalData$id), ]

pppSessions <- cbind(pppSessions, physiologicalData[physiologicalData$session != 1, c("HR", "HRV", "EBR", "SCL")])

# Remove physiological outliers
require(extremevalues)
out <- getOutliers(pppSessions$HR, method="I", distribution = "normal")
out$R2
pppSessions[out$iRight,]
pppSessions[out$iLeft,]

# The following are identified
# HR: 31,52, HRV: 18,31; SCL: 9,12,13,20,35,37,42,47,51; EBR: 18,29,52

# Only participant 18 lies outside normal HRV range
pppSessions[pppSessions$id %in% c(18),"HRV"] = NA # Clean data
pppSessions[is.na(pppSessions)] <- NA

pppSessions <- within(pppSessions, {
  id <- factor(id)
  session <- factor(session)
  type <- factor(type)
  HRV <- HRV*1000
})

# Repeated measures on task phases
# (type: 5 = glucose, 6 = aspartame)

require(ez)
# HR
ezANOVA(data = pppSessions, dv = HR, wid = id, within = .(session), between = .(type), type = 3)
ezPlot(x = session, data = pppSessions, dv = HR, wid = id, within = .(session), between = .(type), split = type, type = 3)

# HRV
ezANOVA(data = pppSessions[complete.cases(pppSessions$HRV),], dv = HRV, wid = id, within = .(session), between = .(type), type = 3)
plt <- ezPlot(data = pppSessions[complete.cases(pppSessions$HRV),],
              x = session, 
              dv = HRV, 
              wid = id,
              split = type,
              between = type,
              within = .(session), 
              type = 3,
              x_lab = "Task phase",
              y_lab = "Mean SDNN (ms)",
              split_lab = "Treatment condition",
              levels = list(session = list(new_names = c("Baseline 1","Treatment","Baseline 2")), 
                            type = list(new_names = c("Maltodexrin","Aspartame"))))
require(ggplot2)
plt = plt + theme(text = element_text(size=15))
print(plt)

pairwise.t.test(pppSessions$HRV, pppSessions$session, p.adjust.method = "none", paired = T)

t.test(pppSessions[pppSessions$session == 2,"HRV"], pppSessions[pppSessions$session == 3,"HRV"], paired = T)

# EBR
ezANOVA(data = pppSessions, dv = EBR, wid = id, within = .(session), between = .(type), type = 3)
plt <- ezPlot(data = pppSessions,
              x = session, 
              dv = EBR, 
              wid = id,
              split = type,
              between = type,
              within = .(session), 
              type = 3,
              x_lab = "Task phase",
              y_lab = "Mean blinks per minute",
              split_lab = "Treatment condition",
              levels = list(session = list(new_names = c("Baseline 1","Treatment","Baseline 2")), 
                            type = list(new_names = c("Maltodexrin","Aspartame"))))
require(ggplot2)
plt = plt + theme(text = element_text(size=15))
print(plt)

t.test(EBR ~ type, data = subset(pppSessions[pppSessions$session == 3,]))

# SCL
## Scale SCL between -1 and 1
for (i in unique(pppSessions$id)) {
  maxSCL <- max(pppSessions[pppSessions$id == i,"SCL"])
  minSCL <- min(pppSessions[pppSessions$id == i,"SCL"])
  for (t in unique(pppSessions$session)) {
    x <- pppSessions[pppSessions$session == t & pppSessions$id == i,"SCL"]
    
    pppSessions[pppSessions$session == t & pppSessions$id == i,"SCL"] <-
      2*((x - minSCL)/(maxSCL - minSCL)) - 1
  }
}

ezANOVA(data = pppSessions[complete.cases(pppSessions$SCL),], dv = SCL, wid = id, within = .(session), between = .(type), type = 3)
# There appears to be a treatment dependent decrease in SCL for the aspartame condition, but this does not reach significance in omnibus
temp <- pppSessions[complete.cases(pppSessions$SCL),]
t.test(temp[temp$session == 1 & temp$type == 6,"SCL"], 
       temp[temp$session == 2 & temp$type == 6,"SCL"], paired = T)
pairwise.t.test(temp[temp$type == 6,"SCL"],temp[temp$type == 6,"session"], p.adjust.method = "holm", paired = T)

plt <- ezPlot(data = pppSessions[complete.cases(pppSessions$SCL),],
              x = session, 
              dv = SCL, 
              wid = id,
              split = type,
              between = type,
              within = .(session), 
              type = 3,
              x_lab = "Task phase",
              y_lab = "Mean skin conductance level change (%)",
              split_lab = "Treatment condition",
              levels = list(session = list(new_names = c("Baseline 1","Treatment","Baseline 2")), 
                            type = list(new_names = c("Maltodexrin","Aspartame"))))
require(ggplot2)
plt = plt + theme(text = element_text(size=15))
print(plt)

# Compare to behavioural (mean estimate)
ezANOVA(data = pppSessions, dv = M, wid = id, within = .(session), between = .(type), type = 3)
pairwise.t.test(pppSessions$M, pppSessions$session, p.adjust.method = "holm", paired = T)
t.test(pppSessions[pppSessions$session == 2,"M"], pppSessions[pppSessions$session == 3,"M"], paired = T)
plt <- ezPlot(data = pppSessions,
              x = session, 
              dv = M, 
              wid = id,
              split = type,
              between = type,
              within = .(session), 
              type = 3,
              x_lab = "Task phase",
              y_lab = "Mean time estimates",
              split_lab = "Treatment condition",
              levels = list(session = list(new_names = c("Baseline 1","Treatment","Baseline 2")), 
                            type = list(new_names = c("Maltodexrin","Aspartame"))))
require(ggplot2)
plt = plt + theme(text = element_text(size=15))
print(plt)

# Compare to behavioural (estimate variability / CV)
ezANOVA(data = pppSessions, dv = CV, wid = id, within = .(session), between = .(type), type = 3)
pairwise.t.test(pppSessions$CV, pppSessions$session, p.adjust.method = "holm", paired = T)
t.test(pppSessions[pppSessions$session == 2,"CV"], pppSessions[pppSessions$session == 3,"CV"], paired = T)
plt <- ezPlot(data = pppSessions,
              x = session, 
              dv = CV, 
              wid = id,
              split = type,
              between = type,
              within = .(session), 
              type = 3,
              x_lab = "Task phase",
              y_lab = "Mean time estimate CV",
              split_lab = "Treatment condition",
              levels = list(session = list(new_names = c("Baseline 1","Treatment","Baseline 2")), 
                            type = list(new_names = c("Maltodexrin","Aspartame"))))
require(ggplot2)
plt = plt + theme(text = element_text(size=15))
print(plt)

# Test for covariance of estimate variabiliy and HRV
coefs <- array()
coefsGlu <- array()
coefsAsp <- array()
c <- 1 
for (i in unique(pppSessions$id)) {
  temp <- subset(pppSessions, id == i)
  coefs[i] <- cor(temp$CV,temp$HRV)
  coefsGlu[c] <- cor(temp[temp$type == 5, "CV"],temp[temp$type == 5, "HRV"])
  coefsAsp[c] <- cor(temp[temp$type == 6, "CV"],temp[temp$type == 6, "HRV"])
    c <- c + 1
}
t.test(coefs)

# Analyse only main phase
ppp <- subset(pppSessions, session == 2)
t.test(HR ~ type, data = ppp)
t.test(HRV ~ type, data = ppp)
t.test(SCL ~ type, data = ppp)
t.test(EBR ~ type, data = ppp)

