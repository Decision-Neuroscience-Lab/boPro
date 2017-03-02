##
# df dataframe
# l vector of colnames
# use the colnames from l to calc a composite z-score
# bgc classification for the base group
# bgtp timepoint/VISCODE for the base group
# Adjusted the calc from x-mean(whole cohort)/sd(whole cohort) to (x - mean(base.group))/sd(base.group)
##
calcZscore <- function(df, l, bgc = "CN", bgtp = "bl"){
  z <- sapply(l, function(cn){
    base.group <- subset(df, DX.simplified == bgc & VISCODE == bgtp)
    zs <- (df[,cn]-mean(base.group[,cn], na.rm=T))/sd(base.group[,cn], na.rm=T)
    if(cn == "TRABSCOR"){ # for trails longer is worse as its a time diference
      zs <- -zs
    }
    zs
    })
  z
}

fn = local({
  i = 0
  function(x) {
    i <<- i + 1
    paste('Figure ', i, ': ', x, sep = '')
  }
})

tn = local({
  i = 0
  function(x) {
    i <<- i + 1
    paste('Table ', i, ': ', x, sep = '')
  }
})

set.pander.options <- function(){
  # panderOptions("table.split.table", Inf)
  panderOptions("table.alignment.default", "center")
  panderOptions("table.style", "multiline")
  panderOptions("digits", 2)
}

simplify.ADNI.DX <- function(dxs){
  dxs <- as.character(dxs)
  dxs <- ifelse(dxs == "MCI to Dementia", "Dementia", dxs)
  dxs <- ifelse(dxs == "NL to Dementia", "Dementia", dxs)
  dxs <- ifelse(dxs == "NL to MCI", "MCI", dxs)
  dxs <- ifelse(dxs == "MCI to NL", "NL", dxs)
  dxs <- ifelse(dxs == "Dementia to MCI", "MCI", dxs)
  dxs <- ifelse(dxs == "Dementia to NL", "NL", dxs)
  dxs <- factor(dxs, levels = c("NL", "MCI", "Dementia"), labels = c("CN", "MCI", "AD"))
  as.character(dxs)
}

# This cleans the "labelled" class that Hmisc appends when importing from ADNIMERGE
clear.labels <- function(x) {
  if(is.list(x)) {
    for(i in 1 : length(x)) class(x[[i]]) <- setdiff(class(x[[i]]), 'labelled') 
    for(i in 1 : length(x)) attr(x[[i]],"label") <- NULL
  }
  else {
    class(x) <- setdiff(class(x), "labelled")
    attr(x, "label") <- NULL
  }
  return(x)
}

# This collapses the mids class generated from MICE into a single data frame with the median imputed values
impMedian <- function(impData) {
  impList <- list()
  # impLong <- data.frame()
  for (i in 1:impData$m){
    temp <- complete(impData,i)
    impList[[i]] <- temp
    # temp$m <- i
    # impLong <- rbind(impLong,temp)
  }
  
  if (any(sapply(temp,is.factor))){
    stop("Cannot handle factors")
  }
  
  require(abind)
  temp2 <- abind(impList, along = 3)
  temp3 <- apply(temp2, c(1,2), median)
  medianData <- data.frame(temp3)

  # for (i in length(medianData)){
  #   medianData[,i] <- as(medianData[,i],origClass[[i]]) # Attempt to covert back to original class
  # }
  return(medianData)
}
  
# This expands '.' notation for formula in plm
expand_formula <- 
  function(form="A ~.",varNames=c("A","B","C")){
    has_dot <- any(grepl('.',form,fixed=TRUE))
    if(has_dot){
      ii <- intersect(as.character(as.formula(form)),
                      varNames)
      varNames <- varNames[!grepl(paste0(ii,collapse='|'),varNames)]
      
      exp <- paste0(varNames,collapse='+')
      as.formula(gsub('.',exp,form,fixed=TRUE))
      
    }
    else as.formula(form)
  }

# Adds time in months to data based on VISCODE
convertVis <- function(rfData){
rfData$time[rfData$VISCODE == "bl"] <- 0
for (i in unique(rfData$VISCODE)){
  if (i != "bl"){
    t <- substring(i,2)
    rfData$time[rfData$VISCODE == i] <- as.numeric(t)
  }
}
return(rfData)}

# Percentage missing columnwise
pMiss <- function(x){sum(is.na(x))/length(x)*100}

# Get mean of duplicates and remove values with high coefficient of variation
consolidateMeta <- function(metabolData, cvCutoff = 0.25) {
  library(data.table)
  metabolData <- as.data.table(sapply(metabolData, as.numeric ))
  # Find CV of dups
  cv <- metabolData[,lapply(.SD, function(x) sd(x, na.rm = T)/mean(x, na.rm = T)),by = "RID"]
  # Get mean of dups
  metabolData <- metabolData[,lapply(.SD, mean, na.rm = T),by = "RID"]
  drop <- cv > cvCutoff
  drop[,1] <- FALSE # Save RIDs
  metabolData[drop] <- NA # Remove values with high CVs
  metabolData[is.na(metabolData)] <- NA
  return(metabolData)
}

# Merge metabolomic data
mergeMetabolomics <- function(VISCODE = "bl") {
    ## This data is janky so we need to do some preprocessing to remove unwanted variables
    ## This includes discarding strings (hope these aren't useful), and consolidating duplicate RIDs (probably technical replications)
    m1 <- subset(admcba[,!grepl("*.Status", colnames(admcba))], ORIGPROT == "ADNI1")
    m1 <- clear.labels(m1[,c(2,10:31)])
    m1 <- consolidateMeta(m1)
    
    m2 <- subset(admcbarcelonapurine, ORIGPROT == "ADNI1")
    m2 <- clear.labels(m2[,c(2,5:12)])
    m2 <- consolidateMeta(m2)
    
    m3 <- subset(admcdukep180fia, ORIGPROT == "ADNI1")
    m3 <- clear.labels(m3[,c(2,10:150)])
    m3 <- consolidateMeta(m3)
    
    m4 <- subset(admcdukep180uplc, ORIGPROT == "ADNI1")
    m4 <- clear.labels(m4[,c(2,10:50)])
    m4 <- consolidateMeta(m4)
    
    m5 <- subset(admcpdinesipcisratios, ORIGPROT == "ADNI1")
    m5 <- clear.labels(m5[,c(2,4:37)])
    m5 <- consolidateMeta(m5)
    
    m6 <- subset(admcpdipeisratios, ORIGPROT == "ADNI1")
    m6 <- clear.labels(m6[,c(2,4:11)])
    m6 <- consolidateMeta(m6)
    
    m7 <- subset(admcpdipesipcisratios, ORIGPROT == "ADNI1")
    m7 <- clear.labels(m7[,c(2,4:35)])
    m7 <- consolidateMeta(m7)
    
    # Merge all together, and then into main data
    allM <- list(m1, m2, m3, m4, m5, m6, m7)
    mergedM = Reduce(function(...) merge(..., all = F, by = "RID"), allM)
    mergedM <- data.frame(lapply(mergedM,function(x) as.numeric(as.character(x))))
    mergedM$VISCODE <- VISCODE
    return(mergedM)
}

# Pulls SE from RF object (rfsrc)
getErrorRF <- function(obj) {
  100 * c(sapply(obj$yvar.names, function(nn) {
    o.coerce <- randomForestSRC:::coerce.multivariate(obj, nn)
    if (o.coerce$family == "class") {
      tail(o.coerce$err.rate[, 1], 1)
    }
    else {
      tail(o.coerce$err.rate, 1) / var(o.coerce$yvar, na.rm = TRUE)
    }
  }))
}

# Pulls VIMP from RF object (rfsrc)
getVimpRF <- function(obj) {
  vimp <- 100 * do.call(cbind, lapply(obj$yvar.names, function(nn) {
    o.coerce <- randomForestSRC:::coerce.multivariate(obj, nn)
    if (o.coerce$family == "class") {
      o.coerce$importance[, 1]
    }
    else {
      o.coerce$importance / var(o.coerce$yvar, na.rm = TRUE)
    }
  }))
  colnames(vimp) <- obj$yvar.names
  return(data.frame(vimp))
}

## Retrieves variable importance for either univariate or multivariate RF models
getVarImp <- function(data, method = c("uv","mv")){
  if (method == "uv"){
    temp <- data
    # Fit univariate models
    temp2 <- temp[,!names(temp) %in% c("TAU","PTAU181P")]
    fit1 <- randomForest(ABETA142 ~ ., data = temp2, importance = TRUE, na.action = na.omit)
    temp3 <- temp[,!names(temp) %in% c("ABETA142","PTAU181P")]
    fit2 <- randomForest(TAU ~ ., data = temp3, importance = TRUE, na.action = na.omit)
    temp4 <- temp[,!names(temp) %in% c("ABETA142","TAU")]
    fit3 <- randomForest(PTAU181P ~ ., data = temp4, importance = TRUE, na.action = na.omit)
    # Store variable importance
    fit <- list(fit1,fit2,fit3)
    varImp <- c()
    c <- 1
    for (i in fit){
      imp = importance(i, type = 1)
      impFit = rownames(imp)[order(imp[, 1], decreasing=TRUE)]
      varImp <- cbind(varImp,impFit[1:20])
      c <- c + 1
    }
    colnames(varImp) <- c("ABETA142","TAU","PTAU181P")
    varErr <- NULL
  } else if (method == "mv"){
    # Fit multivariate model
    fit <- rfsrc(Multivar(ABETA142, TAU, PTAU181P) ~., data = data, ntree = 400, tree.err=TRUE, na.action = "na.impute", importance = TRUE)
    # Get standard error 
    varErr <- getErrorRF(fit)
    # Get variable importance
    compImp <- getVimpRF(fit)
    varImp <- c()
    for (i in 1:3){
      impFit <- rownames(compImp)[order(compImp[, i], decreasing=TRUE)]
      varImp <- cbind(varImp,impFit[1:20])
    }
    colnames(varImp) <- c("ABETA142(M)","TAU(M)","PTAU181P(M)")
  #   tars <- list("ABETA142","TAU","PTAU181P")
  #   vhVars <- list()
  #   varImp <- c()
  #   for (i in tars){
  #     vhVars[[i]] <- var.select(fit, outcome.target = i, method = "vh.vimp")
  #     message(paste("Finished variable hunting for ", i, ".", sep = ""))
  #     varImp <- cbind(varImp,vhVars[[i]]$topvars[1:10])
  #   }
  }
  return(list(fit = fit, imp = varImp,err = varErr))
}

# Performs LOOCV for univariate random forest and gets ROC for Abeta142 and Tau/Abeta ratio
rocUnivariate <- function(data){
  temp <- data
  temp2 <- temp[complete.cases(temp),]
  temp2$ratio <- temp2$TAU / temp2$ABETA142
  
  x = temp2[,!names(temp2) %in% c("ABETA142","TAU","PTAU181P","ratio")]
  y1 = temp2[,"ABETA142"]
  y2 = temp2[,"TAU"]
  
  # CV loop
  k <- dim(temp2)[1]
  predictions1 <- c()
  predictions2 <- c()
  for (i in 1:k) {
    fit1 <- randomForest(x[-i,], y1[-i], importance = FALSE, na.action = na.omit)
    fit2 <- randomForest(x[-i,], y2[-i], importance = FALSE, na.action = na.omit)
    
    predictions1 <- c(predictions1, predict(fit1, newdata = x[i,]))
    predictions2 <- c(predictions2, predict(fit2, newdata = x[i,]))
    
    message(paste(deparse(substitute(data)), " ", round((i/k)*100, digits = 1), "%", sep = ""))
  }
  
  # Get ROC measures
  ## Abeta142
  y <- factor(temp2$ABETA142 > 192)
  predAbeta <- prediction(predictions1, y)
  perfAbeta <- performance(predAbeta, measure = "tpr", x.measure = "fpr")
  ## Tau
  y <- factor(temp2$ratio < 0.39, labels = c("low","high"))
  p <- predictions2/predictions1 # Calculate Tau/Abeta from predictions
  predTau <- prediction(p, y) # Note this is now ROC for the prediction of the ratio
  perfTau <- performance(predTau, measure = "tpr", x.measure = "fpr")
  pred <- list(abeta = predAbeta, tau = predTau)
  perf <- list(abeta = perfAbeta, tau = perfTau)
  
  return(list(pred = pred, perf = perf))
}

rocMultivariate <- function(data){
  temp <- data[,!names(data) %in% c("PTAU181P")]
  impData <- impute(data = temp) # Need to impute data first so we have full obs for test set later
  
  # CV loop
  k <- dim(impData)[1]
  predictions1 <- c()
  predictions2 <- c()
  for (i in 1:k) {
    fit <- rfsrc(Multivar(ABETA142, TAU) ~., data = impData[-i,], ntree = 400, 
                 tree.err=TRUE, importance = FALSE)
    
    predictions1 <- c(predictions1, predict(fit, newdata = impData[i,!names(impData) %in% c("ABETA142","TAU")], 
                                            outcome = "train", importance="none")$regrOutput$ABETA142$predicted)
    predictions2 <- c(predictions2, predict(fit, newdata = impData[i,!names(impData) %in% c("ABETA142","TAU")], 
                                            outcome = "train", importance="none")$regrOutput$TAU$predicted)
    
    message(paste(deparse(substitute(data)), " ", round((i/k)*100, digits = 1), "%", sep = ""))
  }
  
  # Get ROC measures
  ## Abeta142
  y <- factor(impData$ABETA142 > 192)
  predAbeta <- prediction(predictions1, y)
  perfAbeta <- performance(predAbeta, measure = "tpr", x.measure = "fpr")
  ## Tau
  impData$ratio <- impData$TAU / impData$ABETA142
  y <- factor(impData$ratio < 0.39, labels = c("low","high"))
  p <- predictions2/predictions1 # Calculate Tau/Abeta from predictions
  predTau <- prediction(p, y) # Note this is now ROC for the prediction of the ratio
  perfTau <- performance(predTau, measure = "tpr", x.measure = "fpr")
  pred <- list(abeta = predAbeta, tau = predTau)
  perf <- list(abeta = perfAbeta, tau = perfTau)
  
  return(list(pred = pred, perf = perf))
}

# Extracts sensitivity and specificity from ROC performance and prediction objects
opt.cut = function(perf, pred){
  cut.ind = mapply(FUN=function(x, y, p){
    d = (x - 0)^2 + (y-1)^2
    ind = which(d == min(d))
    c(sensitivity = y[[ind]], specificity = 1-x[[ind]],
      cutoff = p[[ind]])
  }, perf@x.values, perf@y.values, pred@cutoffs)
}

# Merge imputations
mergeImps <- function(impPath){
  fileNames <- dir(impPath, pattern =".RData")
  impList = list()
  for(i in 1:length(fileNames)){
    load(paste(cPath,fileNames[i],sep=""))
    impList[[i]] <- imp
  }
  imp <- Reduce(ibind, impList)
  return(imp)
}

# "Universal merge function"
uniMerge <- function(datasets, viscode = "bl", cutoff = 1, keep = c("all","matched","first")){
  for (i in 1:length(datasets)){
    
    # Clear labels
    datasets[[i]] <- clear.labels(datasets[[i]])
    
    if ("VISCODE" %in% colnames(datasets[[i]])){
      # Extract baseline
      datasets[[i]] <- subset(datasets[[i]], VISCODE == "bl")
    }
    
    # Drop coding names
    datasets[[i]] <- datasets[[i]][,!names(datasets[[i]]) %in% c("VISCODE","ORIGPROT","EXAMDATE","RBMID","RECDATE",
                                                                 "COLPROT","USERDATE","USERDATE2","SITEID","SITE",
                                                                 "SAMPLECOLL","SAMPLEDATE","SAMPLETIME","SENTTIME",
                                                                 "GLUCOSENULL","HCTESTDT","HCVOLUME","HCRECEIVE",
                                                                 "HCFROZEN","HCRESAMP","HCUSABLE")]
    if (any(duplicated(datasets[[i]]$RID))) {
      nDups <- sum(duplicated(datasets[[i]]$RID))
      # Remove duplicates
      datasets[[i]] <- data.frame(consolidateMeta(datasets[[i]]))
      cat(paste(nDups, " duplicates consolidated in dataset ",i,"\n\n", sep = ""))
    }
    
    # Drop completely missing variables within datasets
    completelyMissing <- colSums(is.na(datasets[[i]])) == nrow(datasets[[i]])
    datasets[[i]] <- datasets[[i]][,!completelyMissing]
    if (any(completelyMissing)) cat(paste(
      "Missing completely from dataset ", i,":\n", paste(names(completelyMissing[completelyMissing]), collapse = ", "),"\n\n", sep = ""))
    
  }
  
  if (keep == "all"){ # If we want to keep every unmatched observation
    mergedDatasets = Reduce(function(...) merge(..., all = T, by = "RID"), datasets)
  } else if (keep == "matched"){ # If we want to keep only matched observations
    mergedDatasets = Reduce(function(...) merge(..., all = F, by = "RID"), datasets)
  } else if (keep == "first"){ # If we want to keep only observations matched to the first datset
    mergedDatasets = Reduce(function(...) merge(..., all.x = T, all.y = F, by = "RID"), datasets)
  }
  
  # Drop variables with high percentage of missingness
  someMissing <- colSums(is.na(mergedDatasets))/nrow(mergedDatasets) > cutoff
  mergedDatasets <- mergedDatasets[,!someMissing]
  if (any(someMissing)) cat(paste("More than ", cutoff*100,"% missing in merged dataset:\n", 
                  paste(names(someMissing[someMissing]), collapse = ", "), "\n\n", sep = ""))
  
  return(mergedDatasets)
}