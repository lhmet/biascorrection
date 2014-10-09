#' debias
#' 
#' Applies bias correction derived from forecast and observation data to forecast data set
#' 
#' @param fcst array of forecast values (nlead, nyear, nens)
#' @param obs array of observations (nlead, nyear)
#' @param method character string with bias correction method name
#' @param crossval logical, should leave-one-out crossvalidation be used (see details)?
#' @param fcst.out array of forecast values to which bias correction
#' should be applied (defaults to \code{fcst})
#' @param fc.time forecast dates of class 'Date' (for monthly correction, 
#' see \code{\link{monthly}})
#' @param ... additional arguments passed to bias correction methods
#' 
#' @details
#' If \code{crossval} is set to \code{TRUE}, the debiasing for year \code{i} is computed
#' based on the forecast and observation data set excluding year \code{i}. If, in addition,
#' there are more years in the output set \code{fcst.out} than in the input set \code{fcst},
#' the bias correction for the remaining years in \code{fcst.out} is computed based on all 
#' years in \code{fcst}.
#' 
#' @examples
#' ## initialise forcast observation pairs
#' fcst <- array(rnorm(30*215*51, mean=1, sd=rep(seq(0.5,2, length=30), each=215)), 
#' c(215, 30, 51)) + 0.5*sin(seq(0,4,length=215))
#' obs <- array(rnorm(30*215, mean=2), c(215, 30)) + sin(seq(0,4, length=215))
#' fcst.debias <- debias(fcst, obs, 'unbias')
#' ## should be exactly zero
#' range(rowMeans(obs, dims=1) - rowMeans(fcst.debias, dims=1))
#' 
#' @keywords util
#' @export
debias <- function(fcst, obs, method='unbias', crossval=FALSE, fcst.out=fcst, fc.time=NULL, ...){
  ## get name of bias correction function
  dfun <- try(get(method), silent=TRUE)
  if (class(dfun) == 'try-error') stop('Bias correction method has not been implemented yet')
  
  ## apply bias correction function
  if (crossval){
    fcst.debias <- array(NA, dim(fcst.out))
    for (i in 1:ncol(fcst)){
      fcst.debias[,i,] <- dfun(fcst=fcst[,-i,], 
                               obs=obs[,-i], 
                               fcst.out=fcst.out[,i,,drop=F], 
                               fc.time=if (is.null(fc.time)) NULL else fc.time[,-i], 
                               fcout.time=if (is.null(fc.time)) NULL else fc.time[,i,drop=F],
                               ...)
    }
    ## compute the bias for the remaining years from full set
    ## if there are more years in the output than in the input
    if (ncol(fcst.out) > ncol(fcst)){
      ii <- seq(ncol(fcst)+1, ncol(fcst.out))
      fcst.debias[,ii,] <- dfun(fcst=fcst, 
                                obs=obs, 
                                fcst.out=fcst.out[,ii,,drop=F], 
                                fc.time=if (is.null(fc.time)) NULL else fc.time[,1:ncol(fcst)], 
                                fcout.time=if (is.null(fc.time)) NULL else fc.time[,ii,drop=F], 
                                ...)
    }
  } else {
    fcst.debias <- dfun(fcst=fcst, 
                        obs=obs, 
                        fcst.out=fcst.out, 
                        fc.time=fc.time, 
                        ...)
  }
  return(fcst.debias)
}