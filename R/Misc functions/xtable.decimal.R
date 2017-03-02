require(xtable) 

#' Prints a LaTeX table with numeric columns aligned on their decimal points.
#' 
#' This function wraps the \code{\link{xtable}} and \code{\link{print.xtable}}
#' functions in the \code{xtable} package so that numeric columns are aligned
#' on their decimal place.
#' 
#' See \url{http://jason.bryer.org/posts/2013-01-04/xtable_with_aligned_decimals.html}
#' for more information.
#' 
#' @author Jason Bryer <jason@@bryer.org>
#' @param x a data frame to create a LaTeX table from.
#' @param cols a numeric vector indicating which columns should be aligned on
#'        decimal points. It defaults to all columns of type numeric.
#' @param colAlignment named character vector where each element name corresponds to a
#         column name and the value is the LaTeX alignment (i.e. l, r, or c).
#' @param tocharFun the function used to convert the numeric vecotr to a character
#'        vector. This defaults to \code{\link{prettyNum}}, but other possible
#'        options are \code{\link{as.character}}, \code{\link{format}}, 
#'        \code{\link{formatC}}, or some other custom function.
#' @param ... other parameters passed to \code{tocharFun}, \code{\link{xtable}},
#'        and \code{\link{print.xtable}}.
#' @seealso xtable
#' @export
xtable.decimal <- function(x, 
                           cols=which(lapply(x, class) == 'numeric'), 
                           colAlignment, 
                           tocharFun=prettyNum,
                           ...) {
  splitCol <- function(x, ...) {
    s <- strsplit(tocharFun(x, ...), split='.', fixed=TRUE)
    right <- sapply(s, FUN=function(x) { ifelse(length(x) == 2, x[2], '0') })
    left <- sapply(s, FUN=function(x) { x[1] })
    data.frame(left=left, right=right, stringsAsFactors=FALSE)
  }
  
  cols <- cols[order(cols, decreasing=TRUE)]
  colnames <- names(x)
  for(i in cols) {
    if(i == 1) {
      tmp <- cbind(splitCol(x[,1], ...), x[,2:ncol(x)])
      names(tmp)[1:2] <- paste(names(tmp)[1], c('left','right'), sep='.')
      names(tmp)[3:ncol(x)] <- names(x)[2:ncol(x)]
      x <- tmp
    } else if(i == ncol(x)) {
      tmp <- cbind(x[,1:(ncol(x)-1)], splitCol(x[,ncol(x)], ...))
      names(tmp)[1:(ncol(tmp)-2)] <- names(x)[1:(ncol(x)-1)]
      names(tmp)[(ncol(tmp)-1):ncol(tmp)] <- paste(names(x)[ncol(x)], 
                                                   c('left','right'), sep='.')
      x <- tmp
    } else {
      tmp <- cbind(x[,1:(i-1)], splitCol(x[,i], ...), x[,(i+1):ncol(x)])
      names(tmp)[1:(i-1)] <- names(x)[1:(i-1)]
      names(tmp)[i:(i+1)] <- paste(names(x)[i], c('left','right'), sep='.')
      names(tmp)[(i+2):ncol(tmp)] <- names(x)[(i+1):ncol(x)]
      x <- tmp
    }
  }
  
  colnames[cols] <- paste('\\multicolumn{2}{c}{', colnames[cols], '}', sep='')
  colnames <- paste(colnames, collapse=' & ')
  
  addtorow <- list()
  addtorow$pos <- list()
  addtorow$pos[[1]] <- c(0)
  addtorow$command <- paste( colnames, ' \\\\ ', sep='')
  
  align <- rep('l', ncol(x))
  if(!missing(colAlignment)) {
    for(i in seq_along(colAlignment)) {
      align[names(x) == names(colAlignment)[i]] <- colAlignment[i]
    }
  }
  align[grep('.left$', names(x), perl=TRUE)] <- 'r@{.}'
  align <- c('l', align) #Add an alignment for row names
  
  xtab <- xtable(x, align=align, ...)
  print(xtab, add.to.row=addtorow, include.rownames=FALSE, include.colnames=FALSE, ...)
}