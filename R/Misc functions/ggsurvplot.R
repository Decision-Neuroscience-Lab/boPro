ggsurvplot<-function(s, conf.int=T, events=T, shape="|", xlab="Time", 
                     ylab="Survival probability", zeroy=F, col=T, linetype=F){
  
  #s: a survfit object.
  #conf.int: TRUE or FALSE to plot confidence intervals.
  #events: TRUE or FALSE to draw points when censoring events occur
  #shape: the shape of these points
  #zeroy: Force the y axis to reach 0
  #col: TRUE, FALSE or a vector with colours. Colour or B/W
  #linetype: TRUE, FALSE or a vector with line types.
  
  require(ggplot2)
  require(survival)
  
  if(class(s)!="survfit") stop("Survfit object required")
  
  #Build a data frame with all the data
  sdata<-data.frame(time=s$time, surv=s$surv, lower=s$lower, upper=s$upper)
  sdata$strata<-rep(names(s$strata), s$strata)
  
  #Create a blank canvas
  kmplot<-ggplot(sdata, aes(x=time, y=surv))+
    geom_blank()+
    xlab(xlab)+
    ylab(ylab)+
    theme_bw()
  
  #Set color palette
  if(is.logical(col)) ifelse(col,
                             kmplot<-kmplot+scale_colour_brewer(type="qual", palette=6)+scale_fill_brewer(type="qual", palette=6),
                             kmplot<-kmplot+scale_colour_manual(values=rep("black",length(s$strata)))+scale_fill_manual(values=rep("black",length(s$strata)))
  )
  else kmplot<-kmplot+scale_fill_manual(values=col)+scale_colour_manual(values=col)
  
  #Set line types
  if(is.logical(linetype)) ifelse(linetype,
                                  kmplot<-kmplot+scale_linetype_manual(values=1:length(s$strata)),
                                  kmplot<-kmplot+scale_linetype_manual(values=rep(1,  length(s$strata)))
  )
  else kmplot<-kmplot+scale_linetype_manual(values=linetype)
  
  #Force y axis to zero
  if(zeroy) {
    kmplot<-kmplot+ylim(0,1)
  }
  
  #Confidence intervals
  if(conf.int) {  
    
    #Create a data frame with stepped lines
    n <- nrow(sdata)
    ys <- rep(1:n, each = 2)[-2*n] #duplicate row numbers and remove the last one
    xs <- c(1, rep(2:n, each=2))   #first row 1, and then duplicate row numbers
    scurve.step<-data.frame(time=sdata$time[xs], lower=sdata$lower[ys], upper=sdata$upper[ys],  surv=sdata$surv[ys], strata=sdata$strata[ys])
    
    kmplot<-kmplot+
      geom_ribbon(data=scurve.step, aes(x=time,ymin=lower, ymax=upper, fill=strata), alpha=0.2)
  }
  
  #Events
  if(events) {
    kmplot<-kmplot+
      geom_point(aes(x=time, y=surv, col=strata), shape=shape)
  }
  
  #Survival stepped line
  kmplot<-kmplot+geom_step(data=sdata, aes(x=time, y=surv, col=strata, linetype=strata))
  
  #Return the ggplot2 object
  kmplot
}