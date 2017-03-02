# PPP Correlations
## Bowen J Fung, 2016

require(Hmisc)
require(corrgram)
require(ggplot2)
require(xtable)
require(ppcor)
source("/Users/Bowen/Documents/R/misc functions/corrstars.R")
source("/Users/Bowen/Documents/R/misc functions/xtable.decimal.R")

# Load behavioural data
timeData <- read.csv("~/Documents/R/PPP/timeData.txt")
# Load Kubios HRV data
hrv <- read.csv("~/Documents/R/PPP/dataWelch.txt")
# Load other physiological means
physMeans <- read.csv("~/Documents/R/PPP/physMeans.txt")

ppp <- cbind(timeData,hrv,physMeans)

# Remove problem peeps
trialData <- read.csv("~/Documents/R/PPP/trialDataPPP.txt")
ppp <- subset(ppp,id %in% unique(subset(trialData, flag == 0)$id))

# Rename HRV (Kubios actually means bpm...)
names(ppp)[32] <- "bpm"
names(ppp)[33] <- "std_bpm"

# Correlations
vars <- c("meanDiff","stdDiff","cvReproduction",
          "bpm","std_RR","LF_power","HF_power","LF_HF_power",
          "scl","ebr")
temp <- ppp[vars]
corr <- rcorr(as.matrix(temp), type = "spearman")
fdrCorr <- apply(corr$P, 2, p.adjust, method = "BH") # Methods are bonferroni, holm, hochberg, hommel, BH, or BY
corrstars(as.matrix(temp), type = "spearman", method = "none")
xtable(corrstars(as.matrix(temp), type = "spearman", method = "none"))
