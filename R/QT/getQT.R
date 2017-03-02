getQT <- function(data) {
  ### Create data frame
  trialData$postRT <- trialData$rt - trialData$delay
  
  ## Proporiton of quit choices
  propQuit <- aggregate(censor ~ id + distribution, data = trialData[,c("id","distribution","censor")],
                        FUN = function(x) c(prop = sum(x) / length(x), N = length(x)))
  propQuit <- cbind(propQuit[,c("id","distribution")], data.frame(propQuit$censor))
  
  ## Quitting time
  quitTime <- aggregate(rt ~ id + distribution, data = trialData[trialData$censor == 1,c("id","distribution","rt","censor")],
                        FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x) / sd(x), N = length(x)))
  quitTime <- cbind(quitTime[,c("id","distribution")], data.frame(quitTime$rt))
  
  ### Add lost participants
  if (all(trialData$block %in% c(5,6,7,8))) {
  didNotQuit <- c(30) # add 50 to participant number if also no data in pareto
  
  for (i in didNotQuit) {
    r <- i - 1
    d <- 1
    if (i > 50) {
      i <- i - 50
      d <- 2
    }
    missedRow <- c(i,d,NA,NA,NA,0)
    quitTime <- rbind(quitTime[1:r,],missedRow,quitTime[-(1:r),])
  }
  }
  
  
  ## RT (afer maturation)
  RT <- aggregate(postRT ~ id + distribution, data = trialData[trialData$censor == 0, c("id","distribution","postRT")],
                  FUN = function(x) c(M = mean(x), SD = sd(x), CV = mean(x) / sd(x), N = length(x)))
  RT <- cbind(RT[,c("id","distribution")], data.frame(RT$postRT))
  
  ## Earnings
  reward <- aggregate(totalReward ~ id + distribution + block, data = trialData[, c("id","distribution","block","totalReward")],
                      FUN = function(x) c(MAX = max(x)))
  meanReward <- aggregate(totalReward ~ id + distribution, data = reward,
                          FUN = function(x) c(M = mean(x)))
  
  ## Experienced reward rate (this is calculated as the total earnings divided by total time up to each trial)
  rewardRate <- aggregate(rr ~ id + distribution, data = trialData[, c("id","distribution","rr")],
                      FUN = function(x) c(M = mean(x)))

  ## Sequence-adjusted performance (total earnings over mean reward time)
  delayBlock <- aggregate(delay ~ id + distribution + block, data = trialData[, c("id","distribution","block","delay")],
                      FUN = function(x) c(M = mean(x)))
  meanDelay <- aggregate(delay ~ id + distribution, data = delayBlock,
                          FUN = function(x) c(M = mean(x)))
  adjPerf <- meanReward$totalReward / meanDelay$delay
  
  ## AUC
  require(caTools)
  require(OIsurv) # Will also load survival and KMsurv
  res <- 0.1
  upperLimit <- 15
  lengthFunc <- (upperLimit / res) + 1
  AUC <- array(rep(0,length(propQuit$id)))
  times <- array()
  survs <- array()
  id <- numeric()
  distribution <- numeric()
  time <- numeric()
  y <- numeric()
  cond <- numeric()
  c <- 0
  
  for (d in seq(2)) {
    for (i in unique(trialData$id)) {
      c <- c + 1
      temp <- subset(trialData,id == i & distribution == d)
      qts <- Surv(temp$rt,temp$censor,type = "right")
      kmFit <- survfit(qts ~ 1)
      # plot(kmFit, main = "KM estimate", xlab = "Time (secs)", ylab = "Survival function")
      
      times <- rbind(times,kmFit$time)
      survs <- rbind(survs,kmFit$surv)
      AUC[c] <- trapz(kmFit$time,kmFit$surv)
      
      id <- append(id, rep(i,lengthFunc))
      distribution <- append(distribution, rep(d,lengthFunc))
      time <- append(time, approx(kmFit$time,kmFit$surv, xout = seq(0,upperLimit,res))$x)
      y <- append(y,  approx(kmFit$time,kmFit$surv, xout = seq(0,upperLimit,res))$y)
      
      if (i < 26) {
        cond <- append(cond,rep(1,lengthFunc))
      } else {
        cond <- append(cond,rep(2,lengthFunc))
      }
      
    }
  }
  
  ## Params from surivival fits
  # require(flexsurv)
  # params <- matrix(cbind(rep(0,length(propQuit$id)),rep(0,length(propQuit$id)),rep(0,length(propQuit$id))), ncol = 3)
  # c <- 0
  # ids <-  unique(trialData$id)
  # for (d in seq(2)) {
  #   for (i in ids) {
  #     c <- c + 1
  #     if (i == 17) {
  #       params[c,1] <- NA
  #       params[c,2] <- NA
  #       params[c,3] <- NA}
  #     else {
  #       temp <- subset(trialData,id == i & distribution == d)
  #       qts <- Surv(temp$rt,temp$censor)
  #       print(i)
  #       ggFit <- flexsurvreg(Surv(temp$rt,temp$censor) ~ 1, data = uniData, dist = "gengamma")
  #       params[c,1] <- ggFit$coefficients[[1]]
  #       params[c,2] <- ggFit$coefficients[[2]]
  #       params[c,3] <- ggFit$coefficients[[3]]}
  #   }
  # }
  
  ## Questionnaire data
  #qtQualtrics <- read.csv("~/Documents/R/QT/qtQuestionnaires.csv")
  #qtQualtrics <- qtQualtrics[-c(32,34),] # Remove excluded participants
  
  ## Thirst data
  # read.csv("~/Documents/R/QT/trialData.csv")
  
  ## Collate into single frame
  cond <- c(rep(0,length(propQuit$id)))
  cond[propQuit$id < 26] <- 1
  cond[propQuit$id >= 26] <- 2
  qtData <-
    data.frame(
      propQuit$id,cond,propQuit$distribution,propQuit$prop,quitTime$M,quitTime$SD,quitTime$CV,RT$M,RT$SD,
      meanReward$totalReward,AUC,rewardRate$rr,adjPerf
    )
  names(qtData) <-
    c(
      "id","cond","distribution","propQuit","M","SD","CV","RT","RTSD",
      "earnings","AUC","rewardRate","adjPerf"
    )
  # qtData[qtData$propQuit == 0,"propQuit"] <- NA # We don't want to do this because 0 is still a proportion!
  # qtData[qtData$mu > 25 & !is.na(qtData$mu),"mu"] <- NA
  # qtData[qtData$sigma > 10 & !is.na(qtData$sigma),"sigma"] <- NA
  # qtData[qtData$Q < -20 & !is.na(qtData$Q),"Q"] <- NA
  
  return(qtData)
}