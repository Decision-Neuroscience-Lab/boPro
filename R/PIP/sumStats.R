# mean.k function
mean.k=function(x) {
  if (is.numeric(x)) round(mean(x, na.rm=TRUE), digits = 2)
  else "N*N"
}

# median.k function
median.k=function(x) {
  if (is.numeric(x)) round(median(x, na.rm=TRUE), digits = 2)
  else "N*N"
}

# sd.k function
sd.k=function(x) {
  if (is.numeric(x)) round(sd(x, na.rm=TRUE), digits = 2)
  else "N*N"
}

# min.k function
min.k=function(x) {
  if (is.numeric(x)) round(min(x, na.rm=TRUE), digits = 2)
  else "N*N"
}

# max.k function
max.k=function(x) {
  if (is.numeric(x)) round(max(x, na.rm=TRUE), digits = 2)
  else "N*N"
}

###########################################################

# sumstats function #

sumstats=function(x) {  # start function sumstats
  sumtable = cbind(as.matrix(colSums(!is.na(x))),
                   sapply(x,mean.k),
                   sapply(x,median.k),
                   sapply(x,sd.k),
                   sapply(x,min.k),
                   sapply(x,max.k))
  sumtable=as.data.frame(sumtable)
  names(sumtable)=c("Obs","Mean","Median","Std.Dev","min","MAX")
  sumtable
}   